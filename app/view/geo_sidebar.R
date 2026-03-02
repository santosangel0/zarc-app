# nolint start: commented_code_linter
# zarc-app / app / view / geo_sidebar.R
# Shiny module: Geographic filter sidebar.
# nolint end

box::use(
  shiny,
  app / logic / ibge,
  app / logic / state,
)

#' Geographic Sidebar UI
#'
#' Renders cascading filter controls for macro-region,
#' state, mesoregion, and year.
#'
#' @param id Character namespace ID.
#' @return A Shiny tag list.
#' @export
ui <- function(id) {
  ns <- shiny$NS(id)
  regions <- ibge$get_regions()

  shiny$tagList(
    shiny$tags$div(
      class = "sidebar-header",
      shiny$tags$img(
        src = "static/marca-embrapa-branco.png",
        alt = "Embrapa",
        class = "sidebar-logo",
        width = "180px"
      ),
      shiny$tags$h3(
        "Embrapa Gado de Leite"
      ),
      shiny$tags$p(
        class = "sidebar-subtitle",
        "Explorador de Produ\u00e7\u00e3o Leiteira"
      )
    ),
    shiny$tags$div(
      class = "sidebar-filters",
      shiny$selectInput(
        ns("region"),
        label = "Macrorregi\u00e3o",
        choices = c(
          "Selecione..." = "",
          stats::setNames(
            regions, names(regions)
          )
        ),
        selected = ""
      ),
      shiny$selectInput(
        ns("state"),
        label = "Estado",
        choices = c(
          "Selecione a regi\u00e3o" = ""
        ),
        selected = ""
      ),
      shiny$selectInput(
        ns("mesoregion"),
        label = "Mesorregi\u00e3o",
        choices = c(
          "Selecione o estado" = ""
        ),
        selected = ""
      ),
      shiny$numericInput(
        ns("year"),
        label = "Ano (PPM)",
        value = as.integer(
          format(Sys.Date(), "%Y")
        ) - 1L,
        min = 1974L,
        max = as.integer(
          format(Sys.Date(), "%Y")
        ),
        step = 1L
      ),
      shiny$tags$hr(),
      shiny$actionButton(
        ns("apply"),
        label = "Aplicar Filtros",
        icon = shiny$icon("filter"),
        class = "btn-apply"
      ),
      shiny$tags$div(
        class = "sidebar-actions",
        shiny$downloadButton(
          ns("export_state"),
          label = "Exportar Sess\u00e3o",
          icon = shiny$icon("download"),
          class = "btn-export"
        )
      )
    )
  )
}

#' Geographic Sidebar Server
#'
#' Handles cascading dropdown logic and emits
#' the current selections via session state.
#'
#' @param id Character namespace ID.
#' @param app_state A reactiveValues object.
#' @export
server <- function(id, app_state) {
  shiny$moduleServer(
    id,
    function(input, output, session) {
      # Region -> State cascade
      shiny$observeEvent(input$region, {
        region_val <- input$region
        is_empty <- (
          is.null(region_val) ||
            region_val == ""
        )
        if (is_empty) {
          shiny$updateSelectInput(
            session, "state",
            choices = c(
              "Selecione a regi\u00e3o" = ""
            ),
            selected = ""
          )
          shiny$updateSelectInput(
            session, "mesoregion",
            choices = c(
              "Select state first" = ""
            ),
            selected = ""
          )
          return()
        }

        states <- ibge$get_states(
          as.integer(input$region)
        )
        choices <- stats::setNames(
          states$id, states$nome
        )
        shiny$updateSelectInput(
          session, "state",
          choices = c(
            "Todos os estados" = "", choices
          ),
          selected = ""
        )
        shiny$updateSelectInput(
          session, "mesoregion",
          choices = c(
            "Selecione o estado" = ""
          ),
          selected = ""
        )
      })

      # State -> Mesoregion cascade
      shiny$observeEvent(input$state, {
        state_val <- input$state
        is_empty <- (
          is.null(state_val) ||
            state_val == ""
        )
        if (is_empty) {
          shiny$updateSelectInput(
            session, "mesoregion",
            choices = c(
              "Select state first" = ""
            ),
            selected = ""
          )
          return()
        }

        mesos <- ibge$get_mesoregions(
          as.integer(input$state)
        )
        choices <- stats::setNames(
          mesos$id, mesos$nome
        )
        shiny$updateSelectInput(
          session, "mesoregion",
          choices = c(
            "Todas as mesorregi\u00f5es" = "", choices
          ),
          selected = ""
        )
      })

      # Apply Filters -> Update state
      shiny$observeEvent(input$apply, {
        regions <- ibge$get_regions()

        if (input$region != "") {
          code <- as.integer(input$region)
          app_state$region_code <- code
          nms <- names(regions)
          vals <- unlist(regions)
          app_state$region_name <- nms[
            vals == code
          ]
        } else {
          app_state$region_code <- NULL
          app_state$region_name <- NULL
        }

        has_state <- (
          !is.null(input$state) &&
            input$state != ""
        )
        if (has_state) {
          app_state$state_code <- as.integer(
            input$state
          )
        } else {
          app_state$state_code <- NULL
        }

        has_meso <- (
          !is.null(input$mesoregion) &&
            input$mesoregion != ""
        )
        if (has_meso) {
          app_state$mesoregion_code <- as.integer(
            input$mesoregion
          )
        } else {
          app_state$mesoregion_code <- NULL
        }

        app_state$year <- input$year
      })

      # State Export
      output$export_state <- shiny$downloadHandler(
        filename = function() {
          paste0(
            "zarc_session_",
            Sys.Date(), ".json"
          )
        },
        content = function(file) {
          state$save_state(app_state, file)
        }
      )
    }
  )
}
