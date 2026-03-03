# nolint start: commented_code_linter
# zarc-app / app / view / step2_climate.R
# Wizard Step 2: Climate Data (INMET).
# Placeholder module that will be populated
# with meteorological station functionality.
# nolint end

box::use(
  shiny,
  bslib,
)

#' Step 2 Climate UI
#' @param id Character namespace ID.
#' @return A Shiny tag list.
#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  shiny$tagList(
    shiny$tags$div(
      class = "step-placeholder p-4",
      shiny$tags$h3(
        shiny$icon("cloud-sun-rain"),
        paste0(
          " Passo 2: Esta\u00e7\u00f5es ",
          "Meteorol\u00f3gicas (INMET)"
        )
      ),
      shiny$tags$hr(),
      shiny$uiOutput(ns("step2_content"))
    )
  )
}

#' Step 2 Climate Server
#' @param id Character namespace ID.
#' @param app_state A `reactiveValues` object
#'   shared with the main server.
#' @export
server <- function(id, app_state) {
  shiny$moduleServer(id, function(
    input, output, session
  ) {
    output$step2_content <- shiny$renderUI({
      locked <- app_state$locked_region

      if (is.null(locked)) {
        # Not locked yet
        shiny$tags$div(
          class = paste0(
            "alert alert-info ",
            "mt-3"
          ),
          shiny$icon("info-circle"),
          paste0(
            " Por favor, confirme sua ",
            "regi\u00e3o no Passo 1 ",
            "para continuar."
          )
        )
      } else {
        # Show locked context summary
        n_locs <- length(
          locked$target_codes
        )
        yr <- app_state$locked_years

        shiny$tags$div(
          class = "mt-3",
          bslib$card(
            bslib$card_header(
              shiny$icon("check-circle"),
              paste0(
                " Regi\u00e3o Confirmada"
              )
            ),
            bslib$card_body(
              shiny$tags$p(
                shiny$tags$strong(
                  "N\u00edvel geogr\u00e1fico: "
                ),
                locked$geo_level
              ),
              shiny$tags$p(
                shiny$tags$strong(
                  "Localidades: "
                ),
                n_locs
              ),
              shiny$tags$p(
                shiny$tags$strong(
                  "Per\u00edodo: "
                ),
                paste0(
                  yr$year_start,
                  " \u2013 ",
                  yr$year_end
                )
              )
            )
          ),
          shiny$tags$div(
            class = paste0(
              "alert alert-secondary ",
              "mt-3"
            ),
            shiny$icon("wrench"),
            paste0(
              " Funcionalidade de dados ",
              "clim\u00e1ticos em ",
              "desenvolvimento..."
            )
          )
        )
      }
    })
  })
}
