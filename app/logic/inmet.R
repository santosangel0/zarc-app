# nolint start: commented_code_linter
# zarc-app / app / logic / inmet.R
# Lógica de negócio pura para dados meteorológicos
# do INMET: busca, filtragem espacial, controle de
# qualidade e cálculo de ITU.
# Sem reatividade Shiny neste arquivo.
# nolint end

box::use(
  DBI,
  duckdb,
  sf,
)

# Diretório dos parquets do zarc-etl (montado no container — ver config.yml).
data_dir <- function() {
  dir <- tryCatch(config::get("zarc_etl_data_dir"), error = function(e) NULL)
  if (is.null(dir) || !nzchar(dir)) {
    dir <- Sys.getenv("ZARC_ETL_DATA_DIR", "/data")
  }
  dir
}

estacoes_path <- function() file.path(data_dir(), "estacoes.parquet")
diario_path <- function() {
  file.path(data_dir(), "inmet_historico_diario_imputado.parquet")
}

# Cobertura temporal do parquet imputado (NASA POWER horário começa em 2001).
DATA_MIN <- as.Date("2001-01-01")
DATA_MAX <- as.Date("2024-12-31")

# Executa uma query DuckDB efêmera (in-memory) lendo parquet via read_parquet.
# DuckDB faz projection/predicate pushdown direto no parquet (eficiente).
db_query <- function(sql, params = NULL) {
  con <- DBI$dbConnect(duckdb$duckdb())
  on.exit(DBI$dbDisconnect(con, shutdown = TRUE), add = TRUE)
  if (is.null(params)) {
    DBI$dbGetQuery(con, sql)
  } else {
    DBI$dbGetQuery(con, sql, params = params)
  }
}

# Aspas simples para um caminho usado em SQL (caminhos vêm da config, não do usuário).
sql_path <- function(p) paste0("'", p, "'")

#' Busca as estações INMET do parquet do zarc-etl.
#'
#' Lê `estacoes.parquet` e mantém apenas estações que
#' possuem série no parquet diário imputado, retornando
#' um objeto `sf` em WGS84. Substitui a chamada à API
#' ao vivo do INMET.
#'
#' @return Objeto `sf` com colunas
#'   `CD_ESTACAO`, `DC_NOME`, `VL_LATITUDE`,
#'   `VL_LONGITUDE` e geometria de pontos.
#' @export
get_stations <- function() {
  # Só estações que possuem série no parquet imputado (evita pontos sem dado).
  sql <- sprintf(
    paste0(
      "SELECT cd_estacao, dc_nome, vl_latitude, vl_longitude ",
      "FROM read_parquet(%s) ",
      "WHERE cd_estacao IN ",
      "(SELECT DISTINCT cd_estacao FROM read_parquet(%s)) ",
      "ORDER BY cd_estacao"
    ),
    sql_path(estacoes_path()), sql_path(diario_path())
  )
  est <- db_query(sql)

  data <- data.frame(
    CD_ESTACAO = as.character(est$cd_estacao),
    DC_NOME = as.character(est$dc_nome),
    VL_LATITUDE = as.numeric(est$vl_latitude),
    VL_LONGITUDE = as.numeric(est$vl_longitude),
    stringsAsFactors = FALSE
  )

  # Drop rows where coords are missing/invalid
  valid <- (
    !is.na(data$VL_LATITUDE) &
      !is.na(data$VL_LONGITUDE)
  )
  data <- data[valid, ]

  # Convert to sf (WGS84 = EPSG:4326)
  sf$st_as_sf(
    data,
    coords = c(
      "VL_LONGITUDE", "VL_LATITUDE"
    ),
    crs = 4326L,
    remove = FALSE
  )
}

#' Filtra estações por Região de Interesse.
#'
#' Realiza interseção espacial para manter apenas
#' estações dentro do polígono da ROI.
#'
#' @param stations_sf Objeto `sf` de estações.
#' @param roi_sf Polígono `sf` da região.
#' @return Objeto `sf` com estações filtradas.
#' @export
filter_stations <- function(
  stations_sf, roi_sf
) {
  # Project both sets to a planar CRS for Brazil (EPSG:5880)
  # This bypasses s2 spherical geometry errors on complex borders.
  if (
    is.na(sf$st_crs(stations_sf)) ||
      sf$st_crs(stations_sf)$epsg != 5880L
  ) {
    stations_sf <- sf$st_transform(
      stations_sf, 5880L
    )
  }
  if (
    is.na(sf$st_crs(roi_sf)) ||
      sf$st_crs(roi_sf)$epsg != 5880L
  ) {
    roi_sf <- sf$st_transform(
      roi_sf, 5880L
    )
  }

  # Ensure valid geometries on the flat plane
  roi_sf <- sf$st_make_valid(roi_sf)

  # Spatial join (inner) using the GEOS planar engine
  joined <- suppressMessages(
    sf$st_join(
      stations_sf, roi_sf,
      join = sf$st_intersects,
      left = FALSE
    )
  )

  # Transform back to WGS84 for leaflet
  sf$st_transform(joined, 4326L)
}

#' Busca dados climáticos diários (imputados) de uma estação.
#'
#' Lê do parquet diário imputado do zarc-etl (INMET com
#' lacunas preenchidas pelo NASA POWER, corrigido por
#' viés). QC e ITU já vêm calculados no parquet. As datas
#' são limitadas à cobertura disponível (2001–2024).
#'
#' @param station_code Código da estação (character).
#' @param start_date Data inicial (Date ou character).
#' @param end_date Data final (Date ou character).
#' @return data.frame com colunas: `date`,
#'   `station_code`, `TEMP_MED`, `TEMP_MAX`,
#'   `UMID_MED`, `UMID_MIN`, `ITU_MED`, `ITU_MAX`,
#'   `TIPO`, `ORIGEM_TEMP`, `ORIGEM_UMID`,
#'   `IMP_TEMP_PCT`, `IMP_UMID_PCT`.
#' @export
fetch_climate_data <- function(
  station_code, start_date, end_date
) {
  empty_df <- data.frame(
    date = as.Date(character(0)),
    station_code = character(0),
    TEMP_MED = numeric(0),
    TEMP_MAX = numeric(0),
    UMID_MED = numeric(0),
    UMID_MIN = numeric(0),
    ITU_MED = numeric(0),
    ITU_MAX = numeric(0),
    TIPO = character(0),
    ORIGEM_TEMP = character(0),
    ORIGEM_UMID = character(0),
    IMP_TEMP_PCT = numeric(0),
    IMP_UMID_PCT = numeric(0),
    stringsAsFactors = FALSE
  )

  # Limita o intervalo pedido à cobertura do parquet.
  sd <- max(as.Date(start_date), DATA_MIN)
  ed <- min(as.Date(end_date), DATA_MAX)
  if (is.na(sd) || is.na(ed) || sd > ed) {
    return(empty_df)
  }

  sql <- sprintf(
    paste0(
      "SELECT data, temp_med, temp_max, umid_med, umid_min, ",
      "itu_med, itu_max, tipo, temp_origem, umid_origem, ",
      "temp_frac_imp, umid_frac_imp ",
      "FROM read_parquet(%s) ",
      "WHERE cd_estacao = ? ",
      "AND data BETWEEN CAST(? AS DATE) AND CAST(? AS DATE) ",
      "ORDER BY data"
    ),
    sql_path(diario_path())
  )
  res <- db_query(
    sql,
    params = list(
      station_code, as.character(sd), as.character(ed)
    )
  )

  if (nrow(res) == 0L) {
    return(empty_df)
  }

  data.frame(
    date = as.Date(res$data),
    station_code = station_code,
    TEMP_MED = res$temp_med,
    TEMP_MAX = res$temp_max,
    UMID_MED = res$umid_med,
    UMID_MIN = res$umid_min,
    ITU_MED = res$itu_med,
    ITU_MAX = res$itu_max,
    TIPO = res$tipo,
    ORIGEM_TEMP = res$temp_origem,
    ORIGEM_UMID = res$umid_origem,
    IMP_TEMP_PCT = round(res$temp_frac_imp * 100, 1),
    IMP_UMID_PCT = round(res$umid_frac_imp * 100, 1),
    stringsAsFactors = FALSE
  )
}

#' Aplica buffer espacial a um polígono.
#'
#' Transforma para um SRC projetado (EPSG:5880,
#' SIRGAS 2000 / Brazil Polyconic) para buffer
#' métrico, depois retorna para WGS84.
#'
#' @param roi_sf Objeto polígono `sf`.
#' @param buffer_km Buffer numérico em quilômetros.
#' @return Polígono `sf` (com buffer) em WGS84.
#' @export
buffer_polygon <- function(roi_sf, buffer_km) {
  # Normaliza para WGS84 primeiro
  roi_sf <- sf$st_transform(roi_sf, 4326L)

  if (buffer_km <= 0) {
    return(roi_sf)
  }

  # Project to metric CRS for buffering
  projected <- sf$st_transform(roi_sf, 5880L)
  buffered <- sf$st_buffer(
    projected,
    dist = buffer_km * 1000
  )
  sf$st_transform(buffered, 4326L)
}
