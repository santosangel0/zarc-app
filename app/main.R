# nolint start: commented_code_linter
# zarc-app / app / main.R
# Root Shiny module for zarc-app.
# nolint end

box::use(
  shiny,
  bslib,
  leaflet,
  sf,
  app / view / geo_sidebar,
  app / view / charts,
  app / view / analysis,
  app / view / data_view,
  app / logic / ibge,
)

#' Main UI
#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  bslib$page_sidebar(
    title = shiny$tags$span(
      shiny$tags$img(
        src = "static/marca-embrapa-branco.png",
        height = "30px",
        class = "me-2"
      ),
      "Embrapa Gado de Leite"
    ),
    theme = bslib$bs_theme(
      version = 5,
      bootswatch = "darkly",
      primary = "#2ecc71",
      success = "#27ae60",
      info = "#3498db",
      base_font = paste0(
        "Inter, system-ui, sans-serif"
      )
    ),
    sidebar = bslib$sidebar(
      width = 360,
      geo_sidebar$ui(ns("geo"))
    ),
    bslib$navset_tab(
      bslib$nav_panel(
        title = shiny$tags$span(
          shiny$icon("map"), " Mapa"
        ),
        shiny$tags$div(
          class = "map-container",
          leaflet$leafletOutput(
            ns("map"),
            height = "calc(100vh - 120px)"
          )
        )
      ),
      bslib$nav_panel(
        title = shiny$tags$span(
          shiny$icon("chart-bar"),
          paste0(
            " Gr\u00e1ficos"
          )
        ),
        charts$ui(ns("charts"))
      ),
      bslib$nav_panel(
        title = shiny$tags$span(
          shiny$icon("chart-line"),
          paste0(
            " An\u00e1lise"
          )
        ),
        analysis$ui(ns("analysis"))
      ),
      bslib$nav_panel(
        title = shiny$tags$span(
          shiny$icon("table"), " Dados"
        ),
        data_view$ui(ns("data_view"))
      )
    )
  )
}

#' Main Server
#' @export
server <- function(id) {
  shiny$moduleServer(id, function(
    input, output, session
  ) {
    ns <- session$ns

    app_state <- shiny$reactiveValues(
      geo_level = NULL,
      target_codes = NULL,
      years = NULL,
      year_start = NULL,
      year_end = NULL,
      milk_data = NULL,
      raw_milk_data = NULL,
      geo_data = NULL,
      apply_trigger = NULL
    )

    geo_sidebar$server("geo", app_state)

    output$map <- leaflet$renderLeaflet({
      leaflet$leaflet() |>
        leaflet$addProviderTiles(
          leaflet$providers$CartoDB.DarkMatter
        ) |>
        leaflet$setView(
          lng = -49.3, lat = -15.8,
          zoom = 4
        )
    })

    # ── Main data observer: apply_trigger
    shiny$observeEvent(
      app_state$apply_trigger,
      {
        shiny$req(
          app_state$apply_trigger,
          app_state$geo_level,
          app_state$target_codes,
          app_state$years
        )

        geo_level <- app_state$geo_level
        codes <- app_state$target_codes
        years <- app_state$years

        # Validate API request
        validation <- (
          ibge$validate_api_request(
            n_categories = 1L,
            n_periods = length(years),
            n_locations = length(codes)
          )
        )

        if (is.character(validation)) {
          shiny$showNotification(
            validation,
            type = "warning",
            duration = 8
          )
          return()
        }

        shiny$showNotification(
          paste0(
            "Carregando ",
            length(codes),
            " localidades..."
          ),
          type = "message",
          duration = 3
        )

        tryCatch(
          {
            # Fetch milk production
            milk <- ibge$fetch_milk_production(
              geo_level, codes, years
            )

            # Store raw data
            app_state$raw_milk_data <- milk
            app_state$milk_data <- milk

            # For the map: use latest year
            latest_yr <- if (nrow(milk) > 0L) {
              max(milk$year)
            } else {
              max(years)
            }

            # Map subdivision level
            subdiv <- switch(geo_level,
              "N2" = "regioes",
              "N3" = "estados",
              "N8" = "mesorregioes",
              "N9" = "microrregioes",
              "N6" = "municipios",
              "estados"
            )

            # Build GeoJSON URL
            geo <- fetch_geo_for_codes(
              geo_level, codes, subdiv
            )
            app_state$geo_data <- geo

            if (
              !is.null(geo) &&
                nrow(milk) > 0L
            ) {
              milk_yr <- milk[
                milk$year == latest_yr,
              ]
              geo <- merge(
                geo, milk_yr,
                by.x = "codarea",
                by.y = "code",
                all.x = TRUE
              )
            }

            # Update map
            proxy <- leaflet$leafletProxy(
              ns("map"), session
            )
            proxy <- proxy |>
              leaflet$clearShapes() |>
              leaflet$clearControls()

            has_data <- (
              !is.null(geo) &&
                "milk_production_liters" %in%
                  names(geo) &&
                any(!is.na(
                  geo$milk_production_liters
                ))
            )

            if (has_data) {
              render_choropleth(
                proxy, geo, latest_yr
              )
            } else if (!is.null(geo)) {
              render_plain(proxy, geo)
            }

            if (
              !is.null(geo) &&
                nrow(geo) > 0L
            ) {
              bbox <- sf$st_bbox(geo)
              proxy |> leaflet$fitBounds(
                lng1 = bbox[["xmin"]],
                lat1 = bbox[["ymin"]],
                lng2 = bbox[["xmax"]],
                lat2 = bbox[["ymax"]]
              )
            }

            shiny$showNotification(
              paste0(
                "Carregados ",
                nrow(milk), " registros"
              ),
              type = "message",
              duration = 3
            )
          },
          error = function(e) {
            shiny$showNotification(
              paste("Erro:", e$message),
              type = "error",
              duration = 8
            )
          }
        )
      },
      ignoreInit = TRUE
    )

    # Wire sub-modules
    charts$server("charts", app_state)
    analysis$server("analysis", app_state)
    data_view$server("data_view", app_state)
  })
}

#' Fetch GeoJSON for selected codes.
#' @keywords internal
fetch_geo_for_codes <- function(
  geo_level, codes, subdiv
) {
  geo_list <- lapply(codes, function(cd) {
    tryCatch(
      {
        ibge$fetch_subdivisions(
          cd, subdiv
        )
      },
      error = function(e) {
        tryCatch(
          ibge$fetch_geojson(
            subdiv, cd
          ),
          error = function(e2) NULL
        )
      }
    )
  })
  geo_list <- Filter(
    function(x) !is.null(x), geo_list
  )
  if (length(geo_list) == 0L) {
    return(NULL)
  }
  do.call(rbind, geo_list)
}

#' Render choropleth map.
#' @keywords internal
render_choropleth <- function(
  proxy, geo, year
) {
  pal <- leaflet$colorNumeric(
    palette = "YlOrRd",
    domain = geo$milk_production_liters,
    na.color = "#555555"
  )

  mun_name <- if (
    "nome" %in% names(geo)
  ) {
    geo$nome
  } else {
    geo$codarea
  }

  labels <- sprintf(
    "<strong>%s</strong><br/>%s L",
    mun_name,
    format(
      geo$milk_production_liters,
      big.mark = ".",
      decimal.mark = ","
    )
  )

  proxy |>
    leaflet$addPolygons(
      data = geo,
      fillColor = ~ pal(
        milk_production_liters
      ),
      fillOpacity = 0.8,
      color = "#222222",
      weight = 1.2,
      opacity = 0.9,
      label = lapply(labels, shiny$HTML),
      labelOptions = leaflet$labelOptions(
        style = list(
          "font-size" = "13px",
          "padding" = "6px 10px"
        )
      ),
      highlightOptions = (
        leaflet$highlightOptions(
          weight = 3,
          color = "#ff6600",
          fillOpacity = 0.95,
          bringToFront = TRUE
        )
      )
    ) |>
    leaflet$addLegend(
      position = "bottomright",
      pal = pal,
      values = geo$milk_production_liters,
      title = paste("Leite (L)", year),
      opacity = 0.9
    )
}

#' Render plain boundary map.
#' @keywords internal
render_plain <- function(proxy, geo) {
  proxy |>
    leaflet$addPolygons(
      data = geo,
      fillColor = "#3498db",
      fillOpacity = 0.3,
      color = "#ecf0f1",
      weight = 1,
      opacity = 0.7,
      highlightOptions = (
        leaflet$highlightOptions(
          weight = 3,
          color = "#ff6600",
          fillOpacity = 0.5,
          bringToFront = TRUE
        )
      )
    )
}
