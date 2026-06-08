# nolint start: commented_code_linter
# zarc-app / app / view / step2_climate.R
# Passo 2 do Wizard: Dados Climáticos (INMET).
# Filtragem espacial de estações, buffer, mapa
# e busca de dados climáticos.
# nolint end

box::use(
  shiny,
  bslib,
  leaflet,
  sf,
  DT,
  app / logic / inmet,
  app / view / climate_data_view,
)

#' UI do Passo 2 — Clima
#' @param id Identificador de namespace (character).
#' @return Lista de tags Shiny.
#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  shiny$tagList(
    shiny$conditionalPanel(
      condition = paste0(
        "output['",
        ns("has_region"),
        "'] == false"
      ),
      shiny$tags$div(
        class = "step-placeholder p-4",
        shiny$tags$div(
          class = "alert alert-info mt-3",
          shiny$icon("info-circle"),
          paste0(
            " Por favor, confirme sua ",
            "regi\u00e3o no Passo 1 ",
            "para continuar."
          )
        )
      )
    ),
    shiny$conditionalPanel(
      condition = paste0(
        "output['",
        ns("has_region"),
        "'] == true"
      ),
      bslib$layout_sidebar(
        sidebar = bslib$sidebar(
          width = 340,
          shiny$tags$h5(
            shiny$icon("cloud-sun-rain"),
            paste0(
              " Esta\u00e7\u00f5es ",
              "Meteorol\u00f3gicas"
            )
          ),
          shiny$tags$p(
            class = "small text-muted",
            paste0(
              "O mapa exibe a Regi\u00e3o ",
              "de Interesse (ROI) e as ",
              "esta\u00e7\u00f5es autom\u00e1ticas ",
              "do INMET dispon\u00edveis. ",
              "Ajuste o raio de buffer ",
              "para incluir esta\u00e7\u00f5es ",
              "pr\u00f3ximas \u00e0 borda."
            )
          ),
          shiny$tags$hr(),
          shiny$sliderInput(
            ns("buffer_km"),
            label = "Buffer (km)",
            min = 0L,
            max = 50L,
            value = 0L,
            step = 5L,
            ticks = FALSE
          ),
          shiny$tags$div(
            class = "mt-2 mb-3",
            shiny$tags$strong(
              paste0(
                "Esta\u00e7\u00f5es ",
                "encontradas: "
              )
            ),
            shiny$textOutput(
              ns("station_count"),
              inline = TRUE
            )
          ),
          shiny$tags$hr(),
          shiny$actionButton(
            ns("fetch_climate"),
            label = paste0(
              "Confirmar Esta\u00e7\u00f5es ",
              "& Buscar Dados"
            ),
            icon = shiny$icon("download"),
            class = paste0(
              "btn-confirm-advance ",
              "btn-success w-100"
            )
          )
        ),
        # ── Main content ──
        bslib$navset_tab(
          bslib$nav_panel(
            title = shiny$tags$span(
              shiny$icon("map"),
              " Mapa"
            ),
            shiny$tags$div(
              class = "map-container",
              leaflet$leafletOutput(
                ns("climate_map"),
                height = paste0(
                  "calc(100vh - 180px)"
                )
              )
            )
          ),
          bslib$nav_panel(
            title = shiny$tags$span(
              shiny$icon("table"),
              paste0(
                " Esta\u00e7\u00f5es"
              )
            ),
            shiny$tags$div(
              class = "mt-3",
              DT$DTOutput(
                ns("stations_table")
              )
            )
          ),
          bslib$nav_panel(
            title = shiny$tags$span(
              shiny$icon("database"),
              " Dados"
            ),
            climate_data_view$ui(ns("climate_data"))
          )
        )
      )
    )
  )
}

#' Server do Passo 2 — Clima
#' @param id Identificador de namespace (character).
#' @param app_state Objeto `reactiveValues`
#'   compartilhado com o server principal.
#' @export
server <- function(id, app_state) {
  shiny$moduleServer(id, function(
    input, output, session
  ) {
    ns <- session$ns

    climate_data_view$server("climate_data", app_state)

    # ── Expõe status da região p/ painel condicional ──
    output$has_region <- shiny$reactive({
      !is.null(app_state$locked_region)
    })
    shiny$outputOptions(
      output, "has_region",
      suspendWhenHidden = FALSE
    )

    # ── ROI original (normalizado para WGS84) ──
    original_roi <- shiny$reactive({
      locked <- app_state$locked_region
      shiny$req(locked)
      geo <- locked$geo_data
      shiny$req(geo)
      inmet$buffer_polygon(geo, 0)
    })

    # ── ROI com buffer ──
    buffered_roi <- shiny$reactive({
      roi <- original_roi()
      shiny$req(roi)

      buf <- input$buffer_km
      if (is.null(buf)) buf <- 0L

      inmet$buffer_polygon(roi, buf)
    })

    # ── Estações filtradas ──
    all_stations <- shiny$reactiveVal(NULL)

    filtered <- shiny$reactive({
      roi <- buffered_roi()
      shiny$req(roi)

      stations <- all_stations()
      if (is.null(stations)) {
        shiny$withProgress(
          message = paste0(
            "Buscando esta\u00e7\u00f5es INMET..."
          ),
          {
            stations <- tryCatch(
              inmet$get_stations(),
              error = function(e) NULL
            )
          }
        )
        if (!is.null(stations)) {
          all_stations(stations)
        } else {
          return(NULL)
        }
      }

      inmet$filter_stations(stations, roi)
    })

    # ── Station count ──
    output$station_count <-
      shiny$renderText({
        st <- filtered()
        if (is.null(st)) "0" else nrow(st)
      })

    # ── Leaflet map ──
    output$climate_map <-
      leaflet$renderLeaflet({
        leaflet$leaflet() |>
          leaflet$addProviderTiles(
            leaflet$providers$CartoDB.DarkMatter
          ) |>
          leaflet$setView(
            lng = -49.3, lat = -15.8,
            zoom = 5
          )
      })

    # Monitora se o mapa foi renderizado p/ evitar atualizações em mapa oculto/0x0
    map_ready <- shiny$reactiveVal(FALSE)
    shiny$observeEvent(input$climate_map_bounds, {
      map_ready(TRUE)
    })

    # Atualiza mapa quando buffer/estações mudam
    shiny$observe({
      shiny$req(map_ready())
      roi <- original_roi()
      buf_roi <- buffered_roi()
      stations <- filtered()
      shiny$req(roi)

      buf_km <- input$buffer_km
      if (is.null(buf_km)) buf_km <- 0L

      proxy <- leaflet$leafletProxy(
        ns("climate_map"), session
      )
      proxy <- proxy |>
        leaflet$clearShapes() |>
        leaflet$clearMarkers()

      # Desenha anel do buffer (se buffer > 0)
      if (buf_km > 0L && !is.null(buf_roi)) {
        ring <- suppressWarnings(
          sf$st_difference(
            sf$st_union(buf_roi),
            sf$st_union(roi)
          )
        )
        if (length(ring) > 0L) {
          ring_sf <- sf$st_sf(
            geometry = sf$st_sfc(
              ring,
              crs = 4326L
            )
          )
          proxy |>
            leaflet$addPolygons(
              data = ring_sf,
              fillColor = "#9b59b6",
              fillOpacity = 0.1,
              color = "#8e44ad",
              weight = 1,
              opacity = 0.5,
              dashArray = "5,5",
              group = "buffer"
            )
        }
      }

      # Desenha ROI original
      proxy |>
        leaflet$addPolygons(
          data = roi,
          fillColor = "#3498db",
          fillOpacity = 0.15,
          color = "#2ecc71",
          weight = 2,
          opacity = 0.8,
          group = "roi"
        )

      # Desenha marcadores das estações
      if (
        !is.null(stations) &&
          nrow(stations) > 0L
      ) {
        proxy |>
          leaflet$addCircleMarkers(
            data = stations,
            radius = 6,
            color = "#e67e22",
            fillColor = "#f39c12",
            fillOpacity = 0.9,
            stroke = TRUE,
            weight = 1,
            label = ~ paste0(
              DC_NOME,
              " (", CD_ESTACAO, ")"
            ),
            labelOptions = (
              leaflet$labelOptions(
                style = list(
                  "font-size" = "12px",
                  "padding" = "4px 8px"
                )
              )
            )
          )
      }

      # Ajusta zoom para área visível
      fit_roi <- if (
        buf_km > 0L && !is.null(buf_roi)
      ) {
        buf_roi
      } else {
        roi
      }
      bbox <- sf$st_bbox(fit_roi)
      proxy |> leaflet$fitBounds(
        lng1 = bbox[["xmin"]],
        lat1 = bbox[["ymin"]],
        lng2 = bbox[["xmax"]],
        lat2 = bbox[["ymax"]]
      )
    })

    # ── Tabela de estações ──
    output$stations_table <- DT$renderDT({
      st <- filtered()
      shiny$req(st)

      display <- data.frame(
        Codigo = st$CD_ESTACAO,
        Nome = st$DC_NOME,
        Latitude = round(
          st$VL_LATITUDE, 4
        ),
        Longitude = round(
          st$VL_LONGITUDE, 4
        ),
        stringsAsFactors = FALSE
      )

      DT$datatable(
        display,
        options = list(
          pageLength = 15L,
          scrollX = TRUE,
          language = list(
            search = "Buscar:",
            info = paste0(
              "Mostrando _START_ a ",
              "_END_ de _TOTAL_"
            ),
            emptyTable = paste0(
              "Nenhuma esta\u00e7\u00e3o",
              " encontrada"
            )
          )
        ),
        rownames = FALSE,
        class = paste0(
          "table table-dark ",
          "table-striped"
        )
      )
    })

    # ── Busca dados climáticos ao clicar no botão ──
    shiny$observeEvent(
      input$fetch_climate,
      {
        stations <- filtered()
        locked_yr <- app_state$locked_years

        has_input <- (
          !is.null(stations) &&
            nrow(stations) > 0L &&
            !is.null(locked_yr)
        )
        if (!has_input) {
          shiny$showNotification(
            paste0(
              "Nenhuma esta\u00e7\u00e3o ",
              "ou per\u00edodo dispon\u00edvel."
            ),
            type = "warning",
            duration = 5
          )
          return()
        }

        yr_start <- locked_yr$year_start
        yr_end <- locked_yr$year_end
        codes <- stations$CD_ESTACAO
        n_total <- length(codes)

        shiny$withProgress(
          message = paste0(
            "Buscando dados clim\u00e1ticos..."
          ),
          value = 0,
          {
            all_data <- list()
            for (i in seq_along(codes)) {
              shiny$incProgress(
                1 / n_total,
                detail = paste0(
                  codes[i],
                  " (", i, "/",
                  n_total, ")"
                )
              )

              start_dt <- paste0(
                yr_start, "-01-01"
              )
              end_dt <- paste0(
                yr_end, "-12-31"
              )

              chunk <- tryCatch(
                inmet$fetch_climate_data(
                  codes[i],
                  start_dt,
                  end_dt
                ),
                error = function(e) {
                  NULL
                }
              )

              if (
                !is.null(chunk) &&
                  nrow(chunk) > 0L
              ) {
                all_data[[i]] <- chunk
              }
            }
          }
        )

        valid <- Filter(
          function(x) !is.null(x),
          all_data
        )

        if (length(valid) > 0L) {
          merged <- do.call(
            rbind, valid
          )
          app_state$climate_data <- merged

          shiny$showNotification(
            paste0(
              "Dados clim\u00e1ticos ",
              "carregados: ",
              nrow(merged),
              " registros de ",
              length(valid),
              " esta\u00e7\u00f5es."
            ),
            type = "message",
            duration = 5
          )
        } else {
          shiny$showNotification(
            paste0(
              "Nenhum dado ",
              "clim\u00e1tico retornado."
            ),
            type = "warning",
            duration = 5
          )
        }
      }
    )
  })
}
