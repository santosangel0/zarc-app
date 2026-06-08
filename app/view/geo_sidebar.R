# nolint start: commented_code_linter
# zarc-app / app / view / geo_sidebar.R
# Módulo Shiny: filtro geográfico em cascata de 4 níveis.
# nolint end

box::use(
  shiny,
  app / logic / ibge,
  app / logic / state,
)

#' UI da Barra Lateral Geográfica
#' @param id Identificador de namespace (character).
#' @return Lista de tags Shiny.
#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  shiny$tagList(
    shiny$tags$div(
      shiny$tags$h5(
        "\U0001F404",
        paste0(
          " Explorador de ",
          "Produ\u00e7\u00e3o Leiteira"
        )
      ),
      shiny$tags$hr()
    ),
    shiny$tags$div(
      class = "sidebar-filters",

      # Input 1: Base Scope
      shiny$selectInput(
        ns("base_scope"),
        label = "Escopo Base",
        choices = c(
          "Brasil" = "brasil",
          "Grande Regi\u00e3o" = "regiao",
          "Estado" = "estado"
        ),
        selected = "estado"
      ),

      # Input 2: Specific Scope
      shiny$selectInput(
        ns("specific_scope"),
        label = "Escopo Espec\u00edfico",
        choices = c(
          "Selecione..." = ""
        ),
        selected = ""
      ),

      # Input 3: Target Granularity
      shiny$selectInput(
        ns("target_granularity"),
        label = "Granularidade",
        choices = c(
          "Selecione..." = ""
        ),
        selected = ""
      ),

      # Input 4: Target Locations (multi)
      shiny$selectizeInput(
        ns("target_locations"),
        label = shiny$tags$span(
          "Localidades Alvo",
          shiny$actionLink(
            ns("select_all"),
            "Todos",
            class = "ms-2 small"
          ),
          " | ",
          shiny$actionLink(
            ns("clear_all"),
            "Limpar",
            class = "small"
          )
        ),
        choices = NULL,
        multiple = TRUE,
        options = list(
          placeholder = paste0(
            "Selecione as ",
            "localidades..."
          ),
          maxOptions = 600L
        )
      ),

      # Year range
      shiny$sliderInput(
        ns("year_range"),
        label = "Intervalo de Anos",
        min = 1974L,
        max = as.integer(
          format(Sys.Date(), "%Y")
        ),
        value = c(2019L, 2023L),
        step = 1L,
        sep = "",
        ticks = FALSE
      ),
      shiny$tags$hr(),
      shiny$actionButton(
        ns("apply"),
        label = "Aplicar Filtros",
        icon = shiny$icon("filter"),
        class = "btn-apply btn-primary w-100"
      ),
      shiny$tags$hr(),
      shiny$tags$div(
        class = "sidebar-actions",
        shiny$downloadButton(
          ns("download_raw"),
          label = "Baixar Dados Brutos",
          class = "btn-export"
        ),
        shiny$downloadButton(
          ns("download_processed"),
          label = paste0(
            "Baixar Filtrados"
          ),
          class = "btn-export"
        ),
        shiny$fileInput(
          ns("import_state"),
          label = paste0(
            "Importar Configura",
            "\u00e7\u00f5es"
          ),
          accept = ".json",
          buttonLabel = "Arquivo",
          placeholder = "Nenhum"
        ),
        shiny$downloadButton(
          ns("export_state"),
          label = paste0(
            "Exportar Sess\u00e3o"
          ),
          class = "btn-export"
        )
      )
    )
  )
}

#' Geographic Sidebar Server
#' @param id Character namespace ID.
#' @param app_state A `reactiveValues` object.
#' @export
server <- function(id, app_state) {
  shiny$moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns
      available_choices <- shiny$reactiveVal(
        character(0)
      )

      # ── Cascata 1: Escopo Base -> Específico
      shiny$observeEvent(
        input$base_scope,
        {
          scope <- input$base_scope

          if (scope == "brasil") {
            shiny$updateSelectInput(
              session, "specific_scope",
              label = "Escopo Espec\u00edfico",
              choices = c(
                "Brasil (todo)" = "all"
              ),
              selected = "all"
            )
          } else if (scope == "regiao") {
            regions <- ibge$get_regions()
            ch <- stats::setNames(
              regions, names(regions)
            )
            shiny$updateSelectInput(
              session, "specific_scope",
              label = paste0(
                "Grande Regi\u00e3o"
              ),
              choices = c(
                "Selecione..." = "", ch
              ),
              selected = ""
            )
          } else {
            states <- ibge$get_all_states()
            ch <- stats::setNames(
              states$id, states$nome
            )
            shiny$updateSelectInput(
              session, "specific_scope",
              label = "Estado",
              choices = c(
                "Selecione..." = "", ch
              ),
              selected = ""
            )
          }

          # Reset downstream
          shiny$updateSelectInput(
            session, "target_granularity",
            choices = c(
              "Selecione..." = ""
            ),
            selected = ""
          )
          shiny$updateSelectizeInput(
            session,
            "target_locations",
            choices = character(0),
            selected = character(0),
            server = TRUE
          )
        },
        ignoreInit = FALSE
      )

      # ── Cascata 2: Específico -> Granularidade
      shiny$observeEvent(
        input$specific_scope,
        {
          specific <- input$specific_scope
          scope <- input$base_scope

          is_empty <- (
            is.null(specific) ||
              specific == ""
          )
          if (is_empty) {
            shiny$updateSelectInput(
              session,
              "target_granularity",
              choices = c(
                "Selecione..." = ""
              ),
              selected = ""
            )
            return()
          }

          if (scope == "brasil") {
            gran <- c(
              "Grande Regi\u00e3o" = "N2",
              "Estado" = "N3"
            )
          } else if (scope == "regiao") {
            gran <- c(
              "Estado" = "N3"
            )
          } else {
            gran <- c(
              "Mesorregi\u00e3o" = "N8",
              "Munic\u00edpio" = "N6"
            )
          }

          shiny$updateSelectInput(
            session,
            "target_granularity",
            choices = c(
              "Selecione..." = "", gran
            ),
            selected = ""
          )

          shiny$updateSelectizeInput(
            session,
            "target_locations",
            choices = character(0),
            selected = character(0),
            server = TRUE
          )
        },
        ignoreInit = TRUE
      )

      # ── Cascata 3: Granularidade -> Localidades
      shiny$observeEvent(
        input$target_granularity,
        {
          gran <- input$target_granularity
          scope <- input$base_scope
          specific <- input$specific_scope

          is_empty <- (
            is.null(gran) || gran == ""
          )
          if (is_empty) {
            shiny$updateSelectizeInput(
              session,
              "target_locations",
              choices = character(0),
              selected = character(0),
              server = TRUE
            )
            return()
          }

          locs <- tryCatch(
            get_locations(
              scope, specific, gran
            ),
            error = function(e) {
              data.frame(
                id = integer(0),
                nome = character(0),
                stringsAsFactors = FALSE
              )
            }
          )

          if (nrow(locs) > 0L) {
            ch <- stats::setNames(
              as.character(locs$id),
              locs$nome
            )
          } else {
            ch <- character(0)
          }

          # Armazena p/ selecionar todos
          available_choices(ch)

          shiny$updateSelectizeInput(
            session,
            "target_locations",
            choices = ch,
            selected = character(0),
            server = TRUE
          )
        },
        ignoreInit = TRUE
      )

      # ── Selecionar Tudo / Limpar Tudo
      shiny$observeEvent(input$select_all, {
        ch <- available_choices()
        if (length(ch) > 0L) {
          shiny$updateSelectizeInput(
            session,
            "target_locations",
            choices = ch,
            selected = unname(ch),
            server = TRUE
          )
        }
      })

      shiny$observeEvent(input$clear_all, {
        ch <- available_choices()
        shiny$updateSelectizeInput(
          session,
          "target_locations",
          choices = ch,
          selected = character(0),
          server = TRUE
        )
      })

      # ── Aplicar -> atualiza app_state
      shiny$observeEvent(input$apply, {
        yr <- input$year_range
        locs <- input$target_locations
        gran <- input$target_granularity

        has_locs <- (
          !is.null(locs) &&
            length(locs) > 0L
        )
        has_gran <- (
          !is.null(gran) && gran != ""
        )

        if (!has_locs || !has_gran) {
          shiny$showNotification(
            paste0(
              "Selecione a ",
              "granularidade e ",
              "ao menos uma ",
              "localidade."
            ),
            type = "warning",
            duration = 5
          )
          return()
        }

        app_state$geo_level <- gran
        app_state$target_codes <- (
          as.integer(locs)
        )
        app_state$years <- seq(
          yr[1], yr[2]
        )
        app_state$year_start <- yr[1]
        app_state$year_end <- yr[2]

        # Trigger data refresh
        app_state$apply_trigger <- (
          Sys.time()
        )
      })

      # ── Importar configurações
      shiny$observeEvent(
        input$import_state,
        {
          file <- input$import_state
          shiny$req(file)
          tryCatch(
            {
              imported <- state$load_state(
                file$datapath
              )

              # Restore UI dropdowns
              restore_ui(
                session, imported
              )

              # Restore app_state directly
              if (!is.null(
                imported$geo_level
              )) {
                app_state$geo_level <- (
                  imported$geo_level
                )
              }
              if (!is.null(
                imported$target_codes
              )) {
                app_state$target_codes <- (
                  as.integer(
                    imported$target_codes
                  )
                )
              }
              if (!is.null(
                imported$years
              )) {
                yrs <- as.integer(
                  imported$years
                )
                app_state$years <- yrs
                app_state$year_start <- (
                  min(yrs)
                )
                app_state$year_end <- (
                  max(yrs)
                )
              }

              # Trigger data refresh
              app_state$apply_trigger <- (
                Sys.time()
              )

              shiny$showNotification(
                paste0(
                  "Configura\u00e7\u00f5es ",
                  "importadas e ",
                  "aplicadas!"
                ),
                type = "message",
                duration = 3
              )
            },
            error = function(e) {
              shiny$showNotification(
                paste(
                  "Erro ao importar:",
                  e$message
                ),
                type = "error",
                duration = 5
              )
            }
          )
        }
      )

      # ── Exportar sessão
      output$export_state <-
        shiny$downloadHandler(
          filename = function() {
            paste0(
              "zarc-session-",
              format(
                Sys.time(),
                "%Y%m%d-%H%M%S"
              ),
              ".json"
            )
          },
          content = function(file) {
            state$save_state(
              app_state, file
            )
          }
        )

      # ── Baixar dados brutos
      output$download_raw <-
        shiny$downloadHandler(
          filename = function() {
            paste0(
              "dados-brutos-",
              Sys.Date(), ".csv"
            )
          },
          content = function(file) {
            df <- app_state$raw_milk_data
            if (!is.null(df)) {
              utils::write.csv(
                df, file,
                row.names = FALSE,
                fileEncoding = "UTF-8"
              )
            }
          }
        )

      # ── Baixar dados processados
      output$download_processed <-
        shiny$downloadHandler(
          filename = function() {
            paste0(
              "dados-filtrados-",
              Sys.Date(), ".csv"
            )
          },
          content = function(file) {
            df <- app_state$milk_data
            if (!is.null(df)) {
              utils::write.csv(
                df, file,
                row.names = FALSE,
                fileEncoding = "UTF-8"
              )
            }
          }
        )
    }
  )
}

#' Fetch target locations based on cascade.
#'
#' @param scope Character base scope.
#' @param specific Character specific scope ID.
#' @param granularity Character target level.
#' @return A data.frame with `id` and `nome`.
#' @keywords internal
get_locations <- function(
  scope, specific, granularity
) {
  if (scope == "brasil") {
    if (granularity == "N2") {
      regions <- ibge$get_regions()
      return(data.frame(
        id = unlist(regions),
        nome = names(regions),
        stringsAsFactors = FALSE
      ))
    }
    if (granularity == "N3") {
      return(ibge$get_all_states())
    }
  }

  if (scope == "regiao") {
    if (granularity == "N3") {
      return(ibge$get_states(
        as.integer(specific)
      ))
    }
  }

  if (scope == "estado") {
    code <- as.integer(specific)
    if (granularity == "N8") {
      return(ibge$get_mesoregions(code))
    }
    if (granularity == "N9") {
      return(ibge$get_microregions(code))
    }
    if (granularity == "N6") {
      return(ibge$get_municipalities(code))
    }
  }

  data.frame(
    id = integer(0),
    nome = character(0),
    stringsAsFactors = FALSE
  )
}

#' Restaura estado da UI a partir de configurações importadas.
#'
#' @param session Objeto de sessão Shiny.
#' @param imported Lista do JSON importado.
#' @keywords internal
restore_ui <- function(session, imported) {
  has_years <- (
    !is.null(imported$year_start) &&
      !is.null(imported$year_end)
  )
  if (has_years) {
    shiny$updateSliderInput(
      session, "year_range",
      value = c(
        as.integer(imported$year_start),
        as.integer(imported$year_end)
      )
    )
  }
}
