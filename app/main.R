# nolint start: commented_code_linter
# zarc-app / app / main.R
# Root Shiny module for zarc-app.
# Wizard orchestrator: manages navigation between
# Step 1 (Scope) and Step 2 (Climate).
# nolint end

box::use(
  shiny,
  bslib,
  app / view / step1_scope,
  app / view / step2_climate,
)

#' Main UI
#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  bslib$page_navbar(
    id = ns("wizard_nav"),
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
    bslib$nav_panel(
      title = shiny$tags$span(
        shiny$icon("map-marked-alt"),
        paste0(
          " 1. Escopo & Produ\u00e7\u00e3o ",
          "Leiteira"
        )
      ),
      value = "step1",
      step1_scope$ui(ns("step1"))
    ),
    bslib$nav_panel(
      title = shiny$tags$span(
        shiny$icon("cloud-sun-rain"),
        " 2. Dados Clim\u00e1ticos"
      ),
      value = "step2",
      step2_climate$ui(ns("step2"))
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

    # ── Global reactive state ──
    app_state <- shiny$reactiveValues(
      # Current selections (Step 1)
      geo_level = NULL,
      target_codes = NULL,
      years = NULL,
      year_start = NULL,
      year_end = NULL,
      milk_data = NULL,
      raw_milk_data = NULL,
      geo_data = NULL,
      apply_trigger = NULL,
      # Locked state (Wizard)
      locked_region = NULL,
      locked_years = NULL,
      step = 1L
    )

    # ── Wire step modules ──
    step1_scope$server("step1", app_state)
    step2_climate$server("step2", app_state)

    # ── Auto-advance on lock ──
    shiny$observeEvent(
      app_state$locked_region,
      {
        if (!is.null(app_state$locked_region)) {
          bslib$nav_select(
            "wizard_nav",
            selected = "step2",
            session = session
          )
        }
      },
      ignoreInit = TRUE,
      ignoreNULL = FALSE
    )

    # ── Return to Step 1 on unlock ──
    shiny$observeEvent(
      app_state$step,
      {
        if (
          identical(app_state$step, 1L) &&
            is.null(app_state$locked_region)
        ) {
          bslib$nav_select(
            "wizard_nav",
            selected = "step1",
            session = session
          )
        }
      },
      ignoreInit = TRUE
    )
  })
}
