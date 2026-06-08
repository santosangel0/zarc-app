# nolint start: commented_code_linter
# zarc-app / app / logic / ibge.R
# Lógica de negócio pura para dados geográficos do IBGE e API SIDRA de produção leiteira.
# Sem reatividade Shiny neste arquivo.
# nolint end

box::use(
  httr2,
  jsonlite,
  sf,
)

#' Tabela de consulta de grandes regiões brasileiras.
#'
#' @return Lista nomeada mapeando nomes de regiões para códigos IBGE.
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

#' Busca estados de uma grande região.
#'
#' @param region_code Código inteiro da grande região IBGE (1-5).
#' @return data.frame com colunas `id` e `nome`.
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

#' Busca mesorregiões de um estado.
#'
#' @param state_code Código inteiro do estado IBGE (ex: 52).
#' @return data.frame com colunas `id` e `nome`.
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

#' Busca todos os estados brasileiros.
#'
#' @return data.frame com `id` e `nome`.
#' @export
get_all_states <- function() {
  url <- paste0(
    "https://servicodados.ibge.gov.br/",
    "api/v1/localidades/estados",
    "?orderBy=nome"
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

#' Busca municípios de um estado.
#'
#' @param state_code Código inteiro do estado IBGE.
#' @return data.frame com `id` e `nome`.
#' @export
get_municipalities <- function(state_code) {
  url <- paste0(
    "https://servicodados.ibge.gov.br/",
    "api/v1/localidades/estados/",
    state_code, "/municipios",
    "?orderBy=nome"
  )
  resp <- httr2$request(url) |>
    httr2$req_retry(max_tries = 3L) |>
    httr2$req_timeout(60L) |>
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

#' Busca polígonos GeoJSON da API Malhas do IBGE.
#'
#' @param level Character: `"regioes"`, `"estados"`,
#'   `"mesorregioes"` ou `"municipios"`.
#' @param code Código IBGE (inteiro ou character).
#' @return Objeto `sf` com geometrias de polígonos.
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

#' Busca subdivisões GeoJSON da API Malhas do IBGE.
#'
#' Retorna divisões geográficas filhas de uma entidade.
#'
#' @param code Código inteiro IBGE da entidade pai.
#' @param subdivision_level Character: nível filho.
#' @return Objeto `sf` com geometrias de polígonos.
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

#' Busca produção leiteira da API Agregados do IBGE.
#'
#' Usa a Tabela 74 (PPM) com Variável 106 e
#' Classificação 80/2682 (Leite) da API
#' Agregados v3 do IBGE. Suporta múltiplos anos.
#'
#' @param geo_level Código do nível geográfico:
#'   `"N2"` (grande região), `"N3"` (estado),
#'   `"N6"` (município), `"N8"` (mesorregião),
#'   `"N9"` (microrregião).
#' @param codes Vetor de inteiros com códigos IBGE.
#' @param years Vetor de inteiros com anos.
#' @return data.frame com colunas `code`, `nome`,
#'   `year` e `milk_production_liters`.
#' @export
fetch_milk_production <- function(
  geo_level, codes, years
) {
  valid <- c(
    "N1", "N2", "N3",
    "N6", "N8", "N9"
  )
  if (!geo_level %in% valid) {
    stop(
      "Invalid geo_level '", geo_level,
      "'. Must be one of: ",
      paste(valid, collapse = ", ")
    )
  }

  codes_str <- paste(codes, collapse = ",")
  years_str <- paste(years, collapse = "|")
  url <- paste0(
    "https://servicodados.ibge.gov.br/",
    "api/v3/agregados/74",
    "/periodos/", years_str,
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
      ") for years=", years_str
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
    yr_names <- names(s$serie)
    yr_vals <- unlist(s$serie)
    cleaned <- clean_sidra_values(yr_vals)
    data.frame(
      code = as.integer(loc$id),
      nome = loc$nome,
      year = as.integer(yr_names),
      milk_production_liters = (
        cleaned * 1000
      ),
      stringsAsFactors = FALSE
    )
  })

  result <- do.call(rbind, rows)
  result[
    !is.na(result$milk_production_liters),
  ]
}

#' Valida requisição à API IBGE contra limite de 100k.
#'
#' A API Agregados permite no máximo 100.000 valores
#' por requisição: categorias x períodos x localidades.
#'
#' @param n_categories Número inteiro de categorias.
#' @param n_periods Número inteiro de períodos.
#' @param n_locations Número inteiro de localidades.
#' @return `TRUE` se válido, ou string de caractere
#'   com a mensagem de erro.
#' @export
validate_api_request <- function(
  n_categories = 1L,
  n_periods,
  n_locations
) {
  total <- n_categories * n_periods * n_locations
  limit <- 100000L
  if (total <= limit) {
    return(TRUE)
  }
  paste0(
    "A requisi\u00e7\u00e3o excede o ",
    "limite de 100.000 valores (",
    format(
      total,
      big.mark = ".",
      decimal.mark = ","
    ),
    "). Reduza o intervalo de ",
    "tempo ou o n\u00famero de ",
    "localidades."
  )
}

#' Limpa strings de valores especiais do IBGE/SIDRA.
#'
#' Converte convenções do IBGE:
#' `"-"` -> 0, `".."` / `"..."` / `"X"` -> NA.
#'
#' @param x Vetor de caracteres com valores brutos.
#' @return Vetor numérico.
#' @export
clean_sidra_values <- function(x) {
  x[x == "-"] <- "0"
  x[x %in% c("..", "...", "X")] <- NA_character_
  suppressWarnings(as.numeric(x))
}

#' Busca microrregiões de um estado.
#'
#' @param state_code Código inteiro do estado IBGE.
#' @return data.frame com `id` e `nome`.
#' @export
get_microregions <- function(state_code) {
  url <- paste0(
    "https://servicodados.ibge.gov.br/",
    "api/v1/localidades/estados/",
    state_code, "/microrregioes"
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
