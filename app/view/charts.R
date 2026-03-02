# nolint start: commented_code_linter
# zarc-app / app / view / charts.R
# Shiny module: animated bar chart and line chart.
# nolint end

box::use(
  shiny,
  plotly,
)

#' Charts Module UI
#'
#' @param id Character namespace ID.
#' @return A Shiny tag list.
#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  shiny$tagList(
    shiny$tags$div(
      class = "chart-container",
      shiny$tags$h4(
        shiny$icon("chart-bar"),
        paste0(
          " Produ\u00e7\u00e3o por ",
          "Localidade (Barras Animadas)"
        )
      ),
      plotly$plotlyOutput(
        ns("bar_chart"),
        height = "450px"
      )
    ),
    shiny$tags$div(
      class = "chart-container mt-4",
      shiny$tags$h4(
        shiny$icon("chart-line"),
        paste0(
          " Evolu\u00e7\u00e3o ",
          "Temporal da Produ\u00e7\u00e3o"
        )
      ),
      plotly$plotlyOutput(
        ns("line_chart"),
        height = "450px"
      )
    )
  )
}

#' Charts Module Server
#'
#' @param id Character namespace ID.
#' @param app_state A `reactiveValues` object.
#' @export
server <- function(id, app_state) {
  shiny$moduleServer(
    id,
    function(input, output, session) {
      output$bar_chart <-
        plotly$renderPlotly({
          shiny$req(app_state$milk_data)
          milk <- app_state$milk_data

          if (nrow(milk) == 0L) {
            return(plotly$plotly_empty())
          }

          # Top 15 producers per year
          top_codes <- unique(
            milk$code[order(
              -milk$milk_production_liters
            )]
          )[seq_len(min(
            15L, length(unique(milk$code))
          ))]
          milk_top <- milk[
            milk$code %in% top_codes,
          ]

          p <- plotly$plot_ly(
            milk_top,
            x = ~nome,
            y = ~milk_production_liters,
            frame = ~year,
            type = "bar",
            marker = list(
              color = "#e67e22",
              line = list(
                color = "#d35400",
                width = 1
              )
            ),
            hovertemplate = paste0(
              "<b>%{x}</b><br>",
              "%{y:,.0f} litros",
              "<extra></extra>"
            )
          ) |>
            plotly$layout(
              xaxis = list(
                title = "",
                tickangle = -45
              ),
              yaxis = list(
                title = paste0(
                  "Produ\u00e7\u00e3o (L)"
                )
              ),
              paper_bgcolor = (
                "rgba(0,0,0,0)"
              ),
              plot_bgcolor = (
                "rgba(0,0,0,0)"
              ),
              font = list(
                color = "#ecf0f1"
              )
            ) |>
            plotly$animation_opts(
              frame = 800,
              transition = 400,
              redraw = FALSE
            )

          p
        })

      output$line_chart <-
        plotly$renderPlotly({
          shiny$req(app_state$milk_data)
          milk <- app_state$milk_data

          if (nrow(milk) == 0L) {
            return(plotly$plotly_empty())
          }

          # Top 10 for readability
          top_codes <- unique(
            milk$code[order(
              -milk$milk_production_liters
            )]
          )[seq_len(min(
            10L, length(unique(milk$code))
          ))]
          milk_top <- milk[
            milk$code %in% top_codes,
          ]

          p <- plotly$plot_ly(
            milk_top,
            x = ~year,
            y = ~milk_production_liters,
            color = ~nome,
            type = "scatter",
            mode = "lines+markers",
            hovertemplate = paste0(
              "<b>%{fullData.name}</b>",
              "<br>Ano: %{x}",
              "<br>%{y:,.0f} litros",
              "<extra></extra>"
            )
          ) |>
            plotly$layout(
              xaxis = list(
                title = "Ano",
                dtick = 1
              ),
              yaxis = list(
                title = paste0(
                  "Produ\u00e7\u00e3o (L)"
                )
              ),
              legend = list(
                orientation = "h",
                y = -0.2
              ),
              paper_bgcolor = (
                "rgba(0,0,0,0)"
              ),
              plot_bgcolor = (
                "rgba(0,0,0,0)"
              ),
              font = list(
                color = "#ecf0f1"
              )
            )

          p
        })
    }
  )
}
