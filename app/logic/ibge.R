# nolint start: commented_code_linter
# zarc-app / app / logic / ibge.R
# Pure business logic for IBGE geographic data and SIDRA milk production API.
# No Shiny reactivity in this file.
# nolint end

box::use(
  httr2,
  jsonlite,
  sf,
)

#' Brazilian macro-regions lookup table.
#'
#' @return A named list mapping region names to IBGE codes.
#' @export
get_regions <- function() {
  list(
    "Norte" = 1L,
    "Nordeste" = 2L,
    "Sudeste" = 3L,
    "Sul" = 4L,
    "Centro-Oeste" = 5L
  )
}

#' Fetch states for a given macro-region.
#'
#' @param region_code Integer IBGE macro-region code (1-5).
#' @return A data.frame with columns `id` and `nome`.
#' @export
get_states <- function(region_code) {
  url <- paste0(
    "https://servicodados.ibge.gov.br/",
    "api/v1/localidades/regioes/",
    region_code, "/estados"
  )
  resp <- httr2$request(url) |>
    httr2$req_retry(max_tries = 3L) |>
    httr2$req_timeout(30L) |>
    httr2$req_error(
      is_error = function(resp) FALSE
    ) |>
    httr2$req_perform()

  data <- httr2$resp_body_json(
    resp,
    simplifyVector = TRUE
  )
  data.frame(
    id = data$id,
    nome = data$nome,
    stringsAsFactors = FALSE
  )
}

#' Fetch mesoregions for a given state.
#'
#' @param state_code Integer IBGE state code (e.g. 52).
#' @return A data.frame with columns `id` and `nome`.
#' @export
get_mesoregions <- function(state_code) {
  url <- paste0(
    "https://servicodados.ibge.gov.br/",
    "api/v1/localidades/estados/",
    state_code, "/mesorregioes"
  )
  resp <- httr2$request(url) |>
    httr2$req_retry(max_tries = 3L) |>
    httr2$req_timeout(30L) |>
    httr2$req_error(
      is_error = function(resp) FALSE
    ) |>
    httr2$req_perform()

  data <- httr2$resp_body_json(
    resp,
    simplifyVector = TRUE
  )
  data.frame(
    id = data$id,
    nome = data$nome,
    stringsAsFactors = FALSE
  )
}

#' Fetch GeoJSON polygons from IBGE Malhas API.
#'
#' @param level Character: `"regioes"`, `"estados"`,
#'   `"mesorregioes"`, or `"municipios"`.
#' @param code Integer or character IBGE code.
#' @return An `sf` object with polygon geometries.
#' @export
fetch_geojson <- function(level, code) {
  valid <- c(
    "regioes", "estados",
    "mesorregioes", "municipios"
  )
  if (!level %in% valid) {
    stop(
      "Invalid level '", level,
      "'. Must be one of: ",
      paste(valid, collapse = ", ")
    )
  }

  base_url <- paste0(
    "https://servicodados.ibge.gov.br/",
    "api/v3/malhas/", level, "/", code
  )

  resp <- httr2$request(base_url) |>
    httr2$req_url_query(
      formato = "application/vnd.geo+json"
    ) |>
    httr2$req_retry(max_tries = 3L) |>
    httr2$req_timeout(60L) |>
    httr2$req_error(
      is_error = function(resp) FALSE
    ) |>
    httr2$req_perform()

  status <- httr2$resp_status(resp)
  if (status >= 400L) {
    stop(
      "IBGE API error (HTTP ", status,
      ") for level=", level,
      ", code=", code
    )
  }

  geojson_text <- httr2$resp_body_string(resp)
  tmp <- tempfile(fileext = ".geojson")
  on.exit(unlink(tmp), add = TRUE)
  writeLines(geojson_text, tmp)
  sf$st_read(tmp, quiet = TRUE)
}

#' Fetch GeoJSON subdivisions from IBGE Malhas API.
#'
#' Returns child geographic divisions of a given entity.
#'
#' @param code Integer IBGE code for parent entity.
#' @param subdivision_level Character: child level.
#' @return An `sf` object with polygon geometries.
#' @export
fetch_subdivisions <- function(
  code,
  subdivision_level = "municipios"
) {
  valid_levels <- c(
    "regioes", "estados",
    "mesorregioes", "municipios"
  )
  idx <- match(subdivision_level, valid_levels)
  if (is.na(idx)) {
    stop(
      "Invalid subdivision_level '",
      subdivision_level, "'."
    )
  }

  intra_map <- c(
    "regiao", "UF",
    "mesorregiao", "municipio"
  )
  intra <- intra_map[idx]

  # Determine parent level from code length
  code_str <- as.character(code)
  ndig <- nchar(code_str)
  parent_level <- if (ndig <= 1L) {
    "regioes"
  } else if (ndig <= 2L) {
    "estados"
  } else if (ndig <= 4L) {
    "mesorregioes"
  } else {
    "municipios"
  }

  base_url <- paste0(
    "https://servicodados.ibge.gov.br/",
    "api/v3/malhas/",
    parent_level, "/", code
  )

  resp <- httr2$request(base_url) |>
    httr2$req_url_query(
      formato = "application/vnd.geo+json",
      intrarregiao = intra,
      qualidade = "intermediaria"
    ) |>
    httr2$req_retry(max_tries = 3L) |>
    httr2$req_timeout(60L) |>
    httr2$req_error(
      is_error = function(resp) FALSE
    ) |>
    httr2$req_perform()

  status <- httr2$resp_status(resp)
  if (status >= 400L) {
    stop(
      "IBGE API error (HTTP ", status,
      ") for code=", code
    )
  }

  geojson_text <- httr2$resp_body_string(resp)

  if (nchar(geojson_text) < 10L) {
    stop(
      "Empty GeoJSON for code=", code,
      ", level=", subdivision_level
    )
  }

  tmp <- tempfile(fileext = ".geojson")
  on.exit(unlink(tmp), add = TRUE)
  writeLines(geojson_text, tmp)
  sf$st_read(tmp, quiet = TRUE)
}

#' Fetch milk production from IBGE Agregados API.
#'
#' Uses Table 74 (PPM) with Variable 106 and
#' Classification 80/2682 (Leite) from the IBGE
#' Agregados API v3.
#'
#' @param geo_level Character geographic level code:
#'   `"N2"` (grande regiao), `"N3"` (estado),
#'   `"N6"` (municipio), `"N8"` (mesorregiao).
#' @param codes Integer vector of IBGE codes at the
#'   given geographic level.
#' @param year Integer year (e.g. 2021).
#' @return A data.frame with columns `code`, `nome`,
#'   `year`, and `milk_production_liters`.
#' @export
fetch_milk_production <- function(
  geo_level, codes, year
) {
  valid <- c("N1", "N2", "N3", "N6", "N8")
  if (!geo_level %in% valid) {
    stop(
      "Invalid geo_level '", geo_level,
      "'. Must be one of: ",
      paste(valid, collapse = ", ")
    )
  }

  codes_str <- paste(codes, collapse = ",")
  url <- paste0(
    "https://servicodados.ibge.gov.br/",
    "api/v3/agregados/74",
    "/periodos/", year,
    "/variaveis/106",
    "?localidades=", geo_level,
    "[", codes_str, "]",
    "&classificacao=80[2682]"
  )

  resp <- httr2$request(url) |>
    httr2$req_retry(max_tries = 3L) |>
    httr2$req_timeout(120L) |>
    httr2$req_error(
      is_error = function(resp) FALSE
    ) |>
    httr2$req_perform()

  status <- httr2$resp_status(resp)

  empty_df <- data.frame(
    code = integer(0),
    nome = character(0),
    year = integer(0),
    milk_production_liters = numeric(0),
    stringsAsFactors = FALSE
  )

  if (status >= 400L) {
    warning(
      "IBGE API error (HTTP ", status,
      ") for year=", year
    )
    return(empty_df)
  }

  body <- httr2$resp_body_json(resp)

  if (length(body) == 0L) {
    return(empty_df)
  }

  series <- body[[1L]]$resultados[[1L]]$series

  if (length(series) == 0L) {
    return(empty_df)
  }

  rows <- lapply(series, function(s) {
    loc <- s$localidade
    val <- s$serie[[as.character(year)]]
    val_num <- suppressWarnings(
      as.numeric(val)
    )
    data.frame(
      code = as.integer(loc$id),
      nome = loc$nome,
      year = as.integer(year),
      milk_production_liters = (
        val_num * 1000
      ),
      stringsAsFactors = FALSE
    )
  })

  result <- do.call(rbind, rows)
  result[
    !is.na(result$milk_production_liters),
  ]
}
