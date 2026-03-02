# nolint start: commented_code_linter
# zarc-app / app / view / analysis.R
# Shiny module: histogram, descriptive statistics,
# and normality test.
# nolint end

box::use(
  shiny,
  plotly,
  app / logic / stats,
)

#' Analysis Module UI
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
        shiny$icon("chart-area"),
        paste0(
          " Distribui\u00e7\u00e3o da ",
          "Produ\u00e7\u00e3o Leiteira"
        )
      ),
      plotly$plotlyOutput(
        ns("histogram"),
        height = "400px"
      )
    ),
    shiny$tags$div(
      class = "stats-container mt-4",
      shiny$tags$h4(
        shiny$icon("table"),
        paste0(
          " Medidas de Tend\u00eancia ",
          "Central e Dispers\u00e3o"
        )
      ),
      shiny$tableOutput(ns("stats_table"))
    ),
    shiny$tags$div(
      class = "normality-container mt-4",
      shiny$tags$h4(
        shiny$icon("flask"),
        " Teste de Normalidade (Shapiro-Wilk)"
      ),
      shiny$uiOutput(
        ns("normality_result")
      )
    )
  )
}

#' Analysis Module Server
#'
#' @param id Character namespace ID.
#' @param app_state A `reactiveValues` object.
#' @export
server <- function(id, app_state) {
  shiny$moduleServer(
    id,
    function(input, output, session) {
      output$histogram <-
        plotly$renderPlotly({
          shiny$req(app_state$milk_data)
          milk <- app_state$milk_data

          if (nrow(milk) == 0L) {
            return(plotly$plotly_empty())
          }

          vals <- (
            milk$milk_production_liters
          )
          vals <- vals[!is.na(vals)]

          p <- plotly$plot_ly(
            x = vals,
            type = "histogram",
            marker = list(
              color = "#1abc9c",
              line = list(
                color = "#16a085",
                width = 1
              )
            ),
            hovertemplate = paste0(
              "Intervalo: %{x}",
              "<br>Frequ\u00eancia: %{y}",
              "<extra></extra>"
            )
          ) |>
            plotly$layout(
              xaxis = list(
                title = paste0(
                  "Produ\u00e7\u00e3o (L)"
                )
              ),
              yaxis = list(
                title = paste0(
                  "Frequ\u00eancia"
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
            )

          p
        })

      output$stats_table <-
        shiny$renderTable(
          {
            shiny$req(app_state$milk_data)
            milk <- app_state$milk_data
            vals <- (
              milk$milk_production_liters
            )
            vals <- vals[!is.na(vals)]

            if (length(vals) == 0L) {
              return(NULL)
            }

            s <- stats$compute_summary(vals)

            data.frame(
              "Estat\u00edstica" = c(
                "M\u00e9dia",
                "Mediana",
                "Desvio Padr\u00e3o",
                "Vari\u00e2ncia",
                "IQR",
                "M\u00ednimo",
                "M\u00e1ximo",
                "N"
              ),
              Valor = c(
                format(
                  s$media,
                  big.mark = ".",
                  decimal.mark = ","
                ),
                format(
                  s$mediana,
                  big.mark = ".",
                  decimal.mark = ","
                ),
                format(
                  s$desvio_padrao,
                  big.mark = ".",
                  decimal.mark = ","
                ),
                format(
                  s$variancia,
                  big.mark = ".",
                  decimal.mark = ","
                ),
                format(
                  s$iqr,
                  big.mark = ".",
                  decimal.mark = ","
                ),
                format(
                  s$minimo,
                  big.mark = ".",
                  decimal.mark = ","
                ),
                format(
                  s$maximo,
                  big.mark = ".",
                  decimal.mark = ","
                ),
                as.character(s$n)
              ),
              stringsAsFactors = FALSE,
              check.names = FALSE
            )
          },
          striped = TRUE,
          hover = TRUE,
          bordered = TRUE,
          width = "100%"
        )

      output$normality_result <-
        shiny$renderUI({
          shiny$req(app_state$milk_data)
          milk <- app_state$milk_data
          vals <- (
            milk$milk_production_liters
          )
          vals <- vals[!is.na(vals)]

          if (length(vals) == 0L) {
            return(shiny$tags$p(
              "Sem dados dispon\u00edveis."
            ))
          }

          result <- stats$test_normality(
            vals
          )

          icon_name <- if (
            isTRUE(result$is_normal)
          ) {
            "check-circle"
          } else {
            "times-circle"
          }

          alert_class <- if (
            isTRUE(result$is_normal)
          ) {
            "alert alert-success"
          } else {
            "alert alert-warning"
          }

          shiny$tags$div(
            class = alert_class,
            shiny$icon(icon_name),
            " ",
            result$interpretation
          )
        })
    }
  )
}
