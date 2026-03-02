# nolint start: commented_code_linter
# zarc-app / app / view / data_view.R
# Shiny module: Data table inspection with
# raw/processed toggle, row sampler, and footer.
# nolint end

box::use(
  shiny,
  DT,
)

#' Data View Module UI
#' @param id Character namespace ID.
#' @return A Shiny tag list.
#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  random_label <- paste0(
    "Aleatórias"
  )
  sample_choices <- c(
    "Primeiras" = "head",
    "Últimas" = "tail"
  )
  sample_choices[[random_label]] <- "random"

  shiny$tagList(
    shiny$tags$div(
      class = "data-controls mt-3",
      shiny$fluidRow(
        shiny$column(
          4,
          shiny$selectInput(
            ns("data_source"),
            label = "Fonte dos Dados",
            choices = c(
              "Dados Brutos" = "raw",
              "Processados" = "processed"
            ),
            selected = "raw"
          )
        ),
        shiny$column(
          4,
          shiny$selectInput(
            ns("row_sample"),
            label = "Amostra de Linhas",
            choices = sample_choices,
            selected = "head"
          )
        ),
        shiny$column(
          4,
          shiny$tags$div(
            class = "mt-4",
            shiny$textOutput(
              ns("row_count")
            )
          )
        )
      )
    ),
    shiny$tags$div(
      class = "data-table-container mt-2",
      DT$DTOutput(ns("data_table"))
    ),
    shiny$tags$div(
      class = "data-footer mt-3 p-3",
      shiny$uiOutput(ns("footer_text"))
    )
  )
}

#' Data View Module Server
#' @param id Character namespace ID.
#' @param app_state A `reactiveValues` object.
#' @export
server <- function(id, app_state) {
  shiny$moduleServer(
    id,
    function(input, output, session) {
      selected_data <- shiny$reactive({
        src <- input$data_source
        if (src == "raw") {
          app_state$raw_milk_data
        } else {
          app_state$milk_data
        }
      })

      sampled_data <- shiny$reactive({
        df <- selected_data()
        shiny$req(df)
        if (nrow(df) == 0L) {
          return(df)
        }

        mode <- input$row_sample

        if (mode == "head") {
          df
        } else if (mode == "tail") {
          df[rev(seq_len(nrow(df))), ]
        } else {
          df[sample(nrow(df)), ]
        }
      })

      output$data_table <-
        DT$renderDT({
          shiny$req(sampled_data())
          DT$datatable(
            sampled_data(),
            options = list(
              pageLength = 10L,
              scrollX = TRUE,
              language = list(
                search = "Buscar:",
                lengthMenu = paste0(
                  "Mostrar ",
                  "_MENU_ registros"
                ),
                info = paste0(
                  "Mostrando _START_ ",
                  "a _END_ de ",
                  "_TOTAL_ registros"
                ),
                infoEmpty = paste0(
                  "Nenhum registro"
                ),
                zeroRecords = paste0(
                  "Nenhum registro ",
                  "encontrado"
                ),
                emptyTable = paste0(
                  "Sem dados"
                ),
                paginate = list(
                  first = "Primeiro",
                  last = paste0(
                    "Último"
                  ),
                  `next` = paste0(
                    "Próximo"
                  ),
                  previous = "Anterior"
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

      output$row_count <-
        shiny$renderText({
          df <- selected_data()
          if (is.null(df)) {
            "0 registros"
          } else {
            paste0(
              format(
                nrow(df),
                big.mark = ".",
                decimal.mark = ","
              ),
              " registros"
            )
          }
        })

      output$footer_text <-
        shiny$renderUI({
          shiny$tags$div(
            shiny$tags$h6(
              shiny$icon("info-circle"),
              " Tratamento dos Dados"
            ),
            shiny$tags$ul(
              shiny$tags$li(
                paste0(
                  "'-' convertido ",
                  "para 0"
                )
              ),
              shiny$tags$li(
                paste0(
                  "'..' e '...' ",
                  "convertidos para NA"
                )
              ),
              shiny$tags$li(
                paste0(
                  "'X' (sigilo) ",
                  "convertido para NA"
                )
              ),
              shiny$tags$li(
                paste0(
                  "Produ\u00e7\u00e3o ",
                  "x1.000 (API em ",
                  "milhares)"
                )
              )
            )
          )
        })
    }
  )
}
