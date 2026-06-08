# nolint start: commented_code_linter
# zarc-app / app / logic / state.R
# Gerenciamento de estado de sessão reativo com
# serialização / desserialização JSON.
# nolint end

box::use(
  shiny,
  jsonlite,
)

#' Cria um novo estado de sessão reativo.
#'
#' Inicializa um objeto reactiveValues com as
#' seleções geográficas e temporais atuais.
#'
#' @return Objeto reactiveValues.
#' @export
create_state <- function() {
  shiny$reactiveValues(
    region_code = NULL,
    region_name = NULL,
    state_code = NULL,
    state_name = NULL,
    mesoregion_code = NULL,
    mesoregion_name = NULL,
    year = as.integer(format(Sys.Date(), "%Y")) - 1L
  )
}

#' Exporta estado da sessão para string JSON.
#'
#' @param state Objeto reactiveValues.
#' @return String JSON (formatada).
#' @export
export_state <- function(state) {
  snapshot <- shiny$isolate(
    shiny$reactiveValuesToList(state)
  )
  snapshot <- lapply(
    snapshot,
    function(x) if (is.null(x)) NA else x
  )
  jsonlite$toJSON(
    snapshot,
    auto_unbox = TRUE,
    pretty = TRUE
  )
}

#' Salva estado da sessão em arquivo JSON.
#'
#' @param state Objeto reactiveValues.
#' @param path Caminho do arquivo JSON de saída.
#' @return O caminho do arquivo (invisivelmente).
#' @export
save_state <- function(state, path) {
  json <- export_state(state)
  writeLines(json, path)
  invisible(path)
}

#' Importa estado da sessão de arquivo JSON.
#'
#' @param state Objeto reactiveValues.
#' @param path Caminho do arquivo JSON de estado.
#' @return O objeto de estado atualizado (invisivelmente).
#' @export
import_state <- function(state, path) {
  if (!file.exists(path)) {
    stop("Arquivo de estado não encontrado: ", path)
  }
  snapshot <- jsonlite$fromJSON(
    readLines(path, warn = FALSE)
  )

  fields <- c(
    "region_code", "region_name",
    "state_code", "state_name",
    "mesoregion_code", "mesoregion_name",
    "year"
  )
  for (field in fields) {
    val <- snapshot[[field]]
    if (is.null(val) || identical(val, NA)) {
      state[[field]] <- NULL
    } else {
      state[[field]] <- val
    }
  }
  invisible(state)
}

#' Carrega estado da sessão de arquivo JSON.
#'
#' Retorna uma lista de configurações sem modificar
#' valores reativos. Usado para restauração de UI.
#'
#' @param path Caminho do arquivo JSON.
#' @return Lista de configurações importadas.
#' @export
load_state <- function(path) {
  if (!file.exists(path)) {
    stop("Arquivo de estado não encontrado: ", path)
  }
  jsonlite$fromJSON(
    readLines(path, warn = FALSE)
  )
}
