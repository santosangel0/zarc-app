# nolint start: commented_code_linter
# zarc-app / app / view / step1_scope.R
# Wizard Step 1: Scope Definition & Milk Production.
# Encapsulates all IBGE geographic selection, map,
# charts, analysis, and data table functionality.
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

#' Step 1 Scope UI
#' @param id Character namespace ID.
#' @return A Shiny tag list.
#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  bslib$layout_sidebar(
    sidebar = bslib$sidebar(
      width = 360,
      geo_sidebar$ui(ns("geo")),
      shiny$tags$hr(),
      # ── Lock / Unlock buttons ──
      shiny$tags$div(
        class = "lock-controls",
        shiny$actionButton(
          ns("confirm_advance"),
          label = paste0(
            "Confirmar Regi\u00e3o & Avan\u00e7ar"
          ),
          icon = shiny$icon("lock"),
          class = paste0(
            "btn-confirm-advance ",
            "btn-success w-100 mt-2"
          )
        ),
        shiny$conditionalPanel(
          condition = paste0(
            "output['",
            ns("is_locked"),
            "'] == true"
          ),
          shiny$actionButton(
            ns("unlock_edit"),
            label = paste0(
              "Editar Sele\u00e7\u00e3o"
            ),
            icon = shiny$icon("unlock"),
            class = paste0(
              "btn-unlock btn-outline-warning ",
              "w-100 mt-2"
            )
          )
        )
      )
    ),
    bslib$navset_tab(
      id = ns("content_tabs"),
      bslib$nav_panel(
        title = shiny$tags$span(
          shiny$icon("map"), " Mapa"
        ),
        shiny$tags$div(
          class = "map-container",
          leaflet$leafletOutput(
            ns("map"),
            height = "calc(100vh - 180px)"
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

#' Step 1 Scope Server
#' @param id Character namespace ID.
#' @param app_state A `reactiveValues` object
#'   shared with the main server.
#' @export
server <- function(id, app_state) {
  shiny$moduleServer(id, function(
    input, output, session
  ) {
    ns <- session$ns

    # ── Wire sub-modules ──
    geo_sidebar$server("geo", app_state)
    charts$server("charts", app_state)
    analysis$server("analysis", app_state)
    data_view$server("data_view", app_state)

    # ── Expose locked status for cond. panel ──
    output$is_locked <- shiny$reactive({
      !is.null(app_state$locked_region)
    })
    shiny$outputOptions(
      output, "is_locked",
      suspendWhenHidden = FALSE
    )

    # ── Map ──
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

    # ── Main data observer: apply_trigger ──
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

            # Build GeoJSON
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

    # ── Confirm Region & Advance ──
    shiny$observeEvent(input$confirm_advance, {
      has_data <- (
        !is.null(app_state$geo_level) &&
          !is.null(app_state$target_codes) &&
          !is.null(app_state$years)
      )
      if (!has_data) {
        shiny$showNotification(
          paste0(
            "Aplique os filtros primeiro ",
            "antes de confirmar."
          ),
          type = "warning",
          duration = 5
        )
        return()
      }

      # Lock the current selection
      app_state$locked_region <- list(
        geo_level = app_state$geo_level,
        target_codes = app_state$target_codes,
        geo_data = app_state$geo_data
      )
      app_state$locked_years <- list(
        years = app_state$years,
        year_start = app_state$year_start,
        year_end = app_state$year_end
      )
      app_state$step <- 2L

      shiny$showNotification(
        paste0(
          "Regi\u00e3o confirmada! ",
          "Avan\u00e7ando para Dados ",
          "Clim\u00e1ticos..."
        ),
        type = "message",
        duration = 3
      )
    })

    # ── Unlock / Edit ──
    shiny$observeEvent(input$unlock_edit, {
      app_state$locked_region <- NULL
      app_state$locked_years <- NULL
      app_state$step <- 1L

      shiny$showNotification(
        paste0(
          "Sele\u00e7\u00e3o desbloqueada. ",
          "Edite os filtros e confirme ",
          "novamente."
        ),
        type = "message",
        duration = 3
      )
    })
  })
}

# ── Helper functions (migrated from main.R) ──

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
