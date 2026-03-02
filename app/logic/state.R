# nolint start: commented_code_linter
# zarc-app / app / logic / state.R
# Reactive session state management with JSON
# serialization / deserialization.
# nolint end

box::use(
  shiny,
  jsonlite,
)

#' Create a new reactive session state.
#'
#' Initializes a reactiveValues object holding the
#' researcher's current geographic and temporal selections.
#'
#' @return A reactiveValues object.
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

#' Export session state to JSON string.
#'
#' @param state A reactiveValues object.
#' @return A JSON string (pretty-printed).
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

#' Save session state to a JSON file.
#'
#' @param state A reactiveValues object.
#' @param path Character file path for JSON output.
#' @return The file path (invisibly).
#' @export
save_state <- function(state, path) {
  json <- export_state(state)
  writeLines(json, path)
  invisible(path)
}

#' Import session state from a JSON file.
#'
#' @param state A reactiveValues object.
#' @param path Character file path to JSON state file.
#' @return The updated state object (invisibly).
#' @export
import_state <- function(state, path) {
  if (!file.exists(path)) {
    stop("State file not found: ", path)
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

#' Load session state from a JSON file.
#'
#' Returns a list of settings without modifying
#' any reactive values. Used for UI restoration.
#'
#' @param path Character file path to JSON file.
#' @return A list of imported settings.
#' @export
load_state <- function(path) {
  if (!file.exists(path)) {
    stop("State file not found: ", path)
  }
  jsonlite$fromJSON(
    readLines(path, warn = FALSE)
  )
}
