# nolint start: commented_code_linter
# zarc-app / app / main.R
# Módulo raiz do Shiny para o zarc-app.
# Orquestrador do Wizard: gerencia a navegação entre
# Passo 1 (Escopo) e Passo 2 (Clima).
# nolint end

box::use(
  shiny,
  bslib,
  app / view / step1_scope,
  app / view / step2_climate,
)

#' UI Principal
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
      "Gado de leite"
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

#' Server Principal
#' @export
server <- function(id) {
  shiny$moduleServer(id, function(
    input, output, session
  ) {
    ns <- session$ns

    # ── Estado reativo global ──
    app_state <- shiny$reactiveValues(
      # Seleções atuais (Passo 1)
      geo_level = NULL,
      target_codes = NULL,
      years = NULL,
      year_start = NULL,
      year_end = NULL,
      milk_data = NULL,
      raw_milk_data = NULL,
      geo_data = NULL,
      apply_trigger = NULL,
      # Estado travado (Wizard)
      locked_region = NULL,
      locked_years = NULL,
      step = 1L,
      # Dados climáticos (Passo 2)
      climate_data = NULL
    )

    # ── Conecta módulos dos passos ──
    step1_scope$server("step1", app_state)
    step2_climate$server("step2", app_state)

    # ── Avanço automático ao travar ──
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

    # ── Retorno ao Passo 1 ao destravar ──
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
