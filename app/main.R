# nolint start: commented_code_linter
# zarc-app / app / main.R
# Entry point for the Rhino application.
# nolint end

box::use(
  shiny,
  leaflet,
  bslib,
  sf,
  app / view / geo_sidebar,
  app / logic / ibge,
  app / logic / state,
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
      base_font = "Inter, system-ui, sans-serif"
    ),
    sidebar = bslib$sidebar(
      width = 340,
      geo_sidebar$ui(ns("geo"))
    ),
    shiny$tags$div(
      class = "map-container",
      leaflet$leafletOutput(
        ns("map"),
        height = "calc(100vh - 80px)"
      )
    )
  )
}

#' Main Server
#' @export
server <- function(id) {
  shiny$moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

      app_state <- state$create_state()

      geo_sidebar$server(
        "geo",
        app_state = app_state
      )

      output$map <- leaflet$renderLeaflet({
        leaflet$leaflet() |>
          leaflet$addTiles() |>
          leaflet$setView(
            lng = -49.5,
            lat = -15.5,
            zoom = 5
          )
      })

      shiny$observeEvent(
        list(
          app_state$region_code,
          app_state$state_code,
          app_state$mesoregion_code,
          app_state$year
        ),
        {
          shiny$req(app_state$region_code)

          target_code <- app_state$region_code
          subdivision <- "estados"

          if (!is.null(app_state$state_code)) {
            target_code <- app_state$state_code
            subdivision <- "mesorregioes"
          }
          if (!is.null(
            app_state$mesoregion_code
          )) {
            target_code <- (
              app_state$mesoregion_code
            )
            subdivision <- "municipios"
          }

          shiny$showNotification(
            paste(
              "Carregando dados para",
              target_code, "..."
            ),
            type = "message",
            duration = 3
          )

          tryCatch(
            {
              geo <- ibge$fetch_subdivisions(
                target_code, subdivision
              )

              # Map subdivision to API geo level
              milk_level <- switch(subdivision,
                "estados" = "N3",
                "mesorregioes" = "N8",
                "municipios" = "N6",
                "N3"
              )

              # Get codes from GeoJSON features
              geo$codarea <- as.integer(
                geo$codarea
              )
              milk_codes <- geo$codarea

              milk <- ibge$fetch_milk_production(
                milk_level,
                milk_codes,
                app_state$year
              )

              if (nrow(milk) > 0L) {
                geo <- merge(
                  geo, milk,
                  by.x = "codarea",
                  by.y = "code",
                  all.x = TRUE
                )
              }

              proxy <- leaflet$leafletProxy(
                ns("map"), session
              )
              proxy <- proxy |>
                leaflet$clearShapes() |>
                leaflet$clearControls()

              has_data <- (
                "milk_production_liters" %in%
                  names(geo) &&
                  any(!is.na(
                    geo$milk_production_liters
                  ))
              )

              if (has_data) {
                render_choropleth(
                  proxy, geo, app_state$year
                )
              } else {
                render_plain(proxy, geo)
              }

              bbox <- sf$st_bbox(geo)
              proxy |> leaflet$fitBounds(
                lng1 = bbox[["xmin"]],
                lat1 = bbox[["ymin"]],
                lng2 = bbox[["xmax"]],
                lat2 = bbox[["ymax"]]
              )

              shiny$showNotification(
                paste0(
                  "Carregados ",
                  nrow(geo), " ",
                  subdivision
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
    }
  )
}

#' Render choropleth polygons on a leaflet proxy.
#' @param proxy Leaflet proxy object.
#' @param geo sf object with milk_production_liters.
#' @param year Integer year for legend title.
#' @keywords internal
render_choropleth <- function(proxy, geo, year) {
  pal <- leaflet$colorNumeric(
    palette = c("#edf8e9", "#006d2c"),
    domain = geo$milk_production_liters,
    na.color = "#cccccc"
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
      fillOpacity = 0.7,
      color = "#ffffff",
      weight = 1,
      opacity = 0.8,
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
          color = "#2ecc71",
          fillOpacity = 0.9,
          bringToFront = TRUE
        )
      )
    ) |>
    leaflet$addLegend(
      position = "bottomright",
      pal = pal,
      values = geo$milk_production_liters,
      title = paste("Leite (L)", year),
      opacity = 0.8
    )
}

#' Render plain polygons (no production data).
#' @param proxy Leaflet proxy object.
#' @param geo sf object.
#' @keywords internal
render_plain <- function(proxy, geo) {
  proxy |>
    leaflet$addPolygons(
      data = geo,
      fillColor = "#3498db",
      fillOpacity = 0.3,
      color = "#ffffff",
      weight = 1,
      opacity = 0.8
    )
}
