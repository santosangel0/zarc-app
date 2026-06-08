# ══════════════════════════════════════════════════════════════════════════════
# test_pipeline_inmet.R
# Executa o pipeline INMET -> Parquet/DuckDB em fases diagnósticas.
# Uso: Rscript tests/test_pipeline_inmet.R
# ══════════════════════════════════════════════════════════════════════════════

cat("\n====================================================\n")
cat("  INMET Pipeline -- Test Script\n")
cat("====================================================\n\n")

# -- FASE 0: Pacotes e configuração ----------------------------------------
cat("-- FASE 0: Carregando pacotes --\n")

required_pkgs <- c(
  "duckdb", "DBI", "httr2", "jsonlite", "dplyr",
  "stringr", "stringi", "readr", "glue", "archive"
)

missing <- required_pkgs[!sapply(required_pkgs, requireNamespace, quietly = TRUE)]
if (length(missing) > 0) {
  cat("ERRO: Pacotes faltando:", paste(missing, collapse = ", "), "\n")
  stop("Pacotes necessarios nao instalados.")
}

suppressPackageStartupMessages({
  library(duckdb)
  library(DBI)
  library(httr2)
  library(jsonlite)
  library(dplyr)
  library(stringr)
  library(stringi)
  library(readr)
  library(glue)
  library(archive)
})

BASE_DIR          <- "D:/Angelo"
RAW_DIR           <- file.path(BASE_DIR, "RAW_INMET")
PARQUET_ESTACOES  <- file.path(BASE_DIR, "estacoes.parquet")
PARQUET_HISTORICO <- file.path(BASE_DIR, "inmet_historico.parquet")
DUCKDB_TEMP       <- file.path(BASE_DIR, "inmet_temp.duckdb")

dir.create(RAW_DIR, recursive = TRUE, showWarnings = FALSE)

INMET_UA <- paste0(
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) ",
  "AppleWebKit/537.36 (KHTML, like Gecko) ",
  "Chrome/120.0.0.0 Safari/537.36"
)

cat("OK: Pacotes carregados e paths configurados.\n")
cat("  BASE_DIR:", BASE_DIR, "\n")
cat("  RAW_DIR:", RAW_DIR, "\n\n")


# -- FASE 1: Metadados das estações (API -> Parquet) -----------------------
cat("-- FASE 1: Fetch estacoes INMET --\n")

resp <- request("https://apitempo.inmet.gov.br/estacoes/T") |>
  req_headers(`User-Agent` = INMET_UA, Accept = "application/json") |>
  req_retry(max_tries = 3) |>
  req_timeout(60) |>
  req_error(is_error = function(resp) FALSE) |>
  req_perform()

status <- resp_status(resp)

if (status >= 400L) {
  cat("WARN: API retornou HTTP", status, "\n")
  if (!file.exists(PARQUET_ESTACOES)) {
    stop("Sem estacoes.parquet e API indisponivel.")
  }
  cat("  Usando Parquet existente.\n")
} else {
  estacoes <- resp |>
    resp_body_string() |>
    fromJSON(simplifyVector = TRUE) |>
    as_tibble()
  cat("  Estacoes retornadas:", nrow(estacoes), "\n")

  estacoes <- estacoes |>
    mutate(
      VL_LATITUDE  = as.numeric(VL_LATITUDE),
      VL_LONGITUDE = as.numeric(VL_LONGITUDE)
    ) |>
    filter(!is.na(VL_LATITUDE), !is.na(VL_LONGITUDE))
  cat("  Estacoes validas:", nrow(estacoes), "\n")

  con <- dbConnect(duckdb())
  duckdb_register(con, "estacoes_view", estacoes)
  dbExecute(con, glue(
    "COPY estacoes_view TO '{PARQUET_ESTACOES}'
     (FORMAT PARQUET, COMPRESSION ZSTD, ROW_GROUP_SIZE 100000)"
  ))
  n <- dbGetQuery(con, glue(
    "SELECT count(*) AS n FROM read_parquet('{PARQUET_ESTACOES}')"
  ))$n
  cat("  OK:", n, "estacoes gravadas em", PARQUET_ESTACOES, "\n")
  dbDisconnect(con, shutdown = TRUE)
}
cat("\n")


# -- FASE 2: Verificar ZIPs existentes ------------------------------------
cat("-- FASE 2: Verificando ZIPs em RAW_INMET --\n")

zip_files <- list.files(RAW_DIR, pattern = "\\.zip$", full.names = TRUE)
cat("  ZIPs encontrados:", length(zip_files), "\n")

if (length(zip_files) == 0) {
  stop("Nenhum ZIP encontrado em RAW_INMET.")
}

for (zf in zip_files) {
  cat(sprintf("  %s: %.1f MB\n", basename(zf), file.size(zf) / 1e6))
}
cat("\n")


# -- FASE 3: Investigação de schema (1 CSV por ZIP) -------------------------
cat("-- FASE 3: Investigacao de schema multi-ano --\n")

diag_results <- list()

for (zip_path in zip_files) {
  year_label <- tools::file_path_sans_ext(basename(zip_path))

  tryCatch({
    zip_contents <- archive(zip_path)
    csv_entries <- zip_contents$path[
      str_detect(zip_contents$path, regex("\\.csv$", ignore_case = TRUE))
    ]
    if (length(csv_entries) == 0) {
      cat("  ", year_label, ": sem CSVs no ZIP\n")
      next
    }

    sample_csv <- csv_entries[1]

    # Leitura raw bytes -- mode = "rb" é crucial no Windows!
    con_csv <- archive_read(zip_path, file = sample_csv, mode = "rb")
    raw_bytes <- readBin(con_csv, raw(), n = 4096)
    close(con_csv)

    raw_text_latin1 <- iconv(
      rawToChar(raw_bytes), from = "latin1", to = "UTF-8", sub = "byte"
    )
    raw_text_utf8 <- iconv(
      rawToChar(raw_bytes), from = "UTF-8", to = "UTF-8", sub = ""
    )

    encoding_guess <- if (nchar(raw_text_utf8) < nchar(raw_text_latin1) * 0.95) {
      "latin1"
    } else {
      "UTF-8"
    }

    lines <- strsplit(raw_text_latin1, "\r?\n")[[1]][1:15]
    lines <- lines[!is.na(lines)]

    header_idx <- which(str_detect(lines, regex("^Data[;(]|^DATA \\(", ignore_case = TRUE)))
    header_line <- if (length(header_idx) > 0) header_idx[1] else NA_integer_

    col_names <- if (!is.na(header_line)) {
      strsplit(lines[header_line], ";")[[1]]
    } else {
      character(0)
    }

    diag_results[[year_label]] <- tibble(
      year        = year_label,
      file_sample = basename(sample_csv),
      encoding    = encoding_guess,
      header_at   = header_line,
      n_columns   = length(col_names)
    )

    cat(sprintf("  %s: encoding=%s, header=line %s, ncols=%d\n",
                year_label, encoding_guess,
                ifelse(is.na(header_line), "NA", as.character(header_line)),
                length(col_names)))

  }, error = function(e) {
    cat("  ", year_label, ": ERRO --", conditionMessage(e), "\n")
  })
}

if (length(diag_results) > 0) {
  diag_df <- bind_rows(diag_results)
  cat("\n  Resumo do diagnostico:\n")
  print(diag_df, n = Inf)
}
cat("\n")


# -- FASE 4: Definir funções de parsing ------------------------------------
cat("-- FASE 4: Definindo funcoes de parsing --\n")

normalize_colnames <- function(x) {
  x |>
    stri_trans_general("Latin-ASCII") |>
    str_to_lower() |>
    str_replace_all("[^a-z0-9]", "_") |>
    str_replace_all("_+", "_") |>
    str_remove("^_") |>
    str_remove("_$")
}

read_inmet_csv <- function(zip_path, csv_name) {
  tryCatch({
    station_code <- str_extract(csv_name, "[A-Z]\\d{3}")
    if (is.na(station_code)) {
      warning(paste("Codigo nao extraido de:", csv_name))
      return(NULL)
    }

    # CRITICAL: mode = "rb" para leitura binaria no Windows
    con_raw <- archive_read(zip_path, file = csv_name, mode = "rb")
    raw_bytes <- readBin(con_raw, raw(), n = 50e6)
    close(con_raw)

    text_utf8 <- iconv(
      rawToChar(raw_bytes),
      from = "latin1",
      to   = "UTF-8",
      sub  = "byte"
    )

    all_lines <- strsplit(text_utf8, "\r?\n")[[1]]

    search_range <- seq_len(min(15, length(all_lines)))
    header_idx <- which(str_detect(
      all_lines[search_range],
      regex("^Data[;(]|^DATA \\(", ignore_case = TRUE)
    ))

    if (length(header_idx) == 0) {
      warning(paste("Header 'Data;' nao encontrado em", csv_name))
      return(NULL)
    }

    data_text <- paste(all_lines[header_idx[1]:length(all_lines)], collapse = "\n")

    df <- read_csv2(
      I(data_text),
      locale         = locale(decimal_mark = ",", grouping_mark = "."),
      na             = c("", "NA", "-9999", "-9999,0"),
      show_col_types = FALSE,
      name_repair    = "unique"
    )

    # Remove colunas fantasma (geradas por ; trailing)
    phantom_cols <- grepl("^\\.\\.\\.", names(df))
    if (any(phantom_cols)) df <- df[, !phantom_cols, drop = FALSE]

    if (nrow(df) == 0) return(NULL)

    # Normaliza nomes de colunas para schema canonico
    names(df) <- normalize_colnames(names(df))

    # Harmoniza schema: old "DATA (YYYY-MM-DD)" -> "data_yyyy_mm_dd" -> "data"
    names(df) <- str_replace(names(df), "^data_yyyy_mm_dd$", "data")

    # Remove colunas residuais com nomes vazios ou numericos puros
    valid_cols <- !grepl("^_*\\d+$", names(df)) & nchar(names(df)) > 0
    df <- df[, valid_cols, drop = FALSE]

    df$cd_estacao <- station_code
    df

  }, error = function(e) {
    warning(paste("Erro ao ler", csv_name, ":", conditionMessage(e)))
    NULL
  })
}

cat("OK: normalize_colnames() e read_inmet_csv() definidas.\n\n")


# -- FASE 4.5: Teste unitário -- parse de 1 CSV ----------------------------
cat("-- FASE 4.5: Teste unitario -- parse de 1 CSV do primeiro ZIP --\n")

test_zip <- zip_files[1]
test_contents <- archive(test_zip)
test_csvs <- test_contents$path[
  str_detect(test_contents$path, regex("\\.csv$", ignore_case = TRUE))
]

if (length(test_csvs) > 0) {
  test_csv <- test_csvs[1]
  cat("  ZIP:", basename(test_zip), "\n")
  cat("  CSV:", basename(test_csv), "\n")

  test_df <- read_inmet_csv(test_zip, test_csv)

  if (!is.null(test_df)) {
    cat("  OK: Linhas:", nrow(test_df), "| Colunas:", ncol(test_df), "\n")
    cat("  Nomes das colunas:\n")
    for (cn in names(test_df)) cat("    -", cn, "\n")
    cat("  Primeiras 3 linhas:\n")
    print(head(test_df, 3))
  } else {
    cat("  FALHA: read_inmet_csv retornou NULL!\n")
  }
} else {
  cat("  FALHA: Nenhum CSV no ZIP de teste.\n")
}
cat("\n")


# -- FASE 5: Cross-reference com catálogo de estações ----------------------
cat("-- FASE 5: Carregando catalogo de estacoes --\n")

con <- dbConnect(duckdb())
station_lookup <- dbGetQuery(con, glue(
  "SELECT DISTINCT CD_ESTACAO FROM read_parquet('{PARQUET_ESTACOES}')"
))$CD_ESTACAO
cat("  Codigos no catalogo:", length(station_lookup), "\n\n")
dbDisconnect(con, shutdown = TRUE)


# -- FASE 6: Ingestão batch-by-year (TODOS os ZIPs) -----------------------
cat("-- FASE 6: Ingestao em lote (batch-by-year -> DuckDB) --\n")

# Remove banco temporario de execucoes anteriores para comecar limpo
for (f in list.files(BASE_DIR, pattern = "inmet_temp\\.duckdb", full.names = TRUE)) {
  file.remove(f)
}

con <- dbConnect(duckdb(), dbdir = DUCKDB_TEMP)

if (dbExistsTable(con, "tabela_clima")) {
  dbRemoveTable(con, "tabela_clima")
  cat("  Tabela tabela_clima removida (re-execucao).\n")
}

total_rows  <- 0
total_files <- 0
t_start     <- Sys.time()

for (zip_path in zip_files) {
  year_label <- tools::file_path_sans_ext(basename(zip_path))
  cat(sprintf("--- %s ---\n", year_label))

  zip_contents <- archive(zip_path)
  csv_entries <- zip_contents$path[
    str_detect(zip_contents$path, regex("\\.csv$", ignore_case = TRUE))
  ]
  cat("  CSVs:", length(csv_entries), "\n")

  year_batch <- list()

  for (csv_name in csv_entries) {
    df <- read_inmet_csv(zip_path, csv_name)
    if (is.null(df) || nrow(df) == 0) next
    if (!df$cd_estacao[1] %in% station_lookup) next

    year_batch[[length(year_batch) + 1]] <- df
    total_files <- total_files + 1
  }

  if (length(year_batch) == 0) {
    cat("  WARN: Nenhum CSV valido.\n\n")
    next
  }

  # Consolida o ano e faz UM UNICO dbWriteTable
  year_df <- bind_rows(year_batch)
  total_rows <- total_rows + nrow(year_df)

  # Forca character para evitar conflito de schema entre anos
  year_df <- year_df |> mutate(across(everything(), as.character))

  dbWriteTable(con, "tabela_clima", year_df, append = TRUE)

  cat(sprintf("  OK: %d linhas (%d CSVs)\n", nrow(year_df), length(year_batch)))
  cat(sprintf("  Total acumulado: %s linhas\n\n", format(total_rows, big.mark = ",")))

  rm(year_batch, year_df)
  gc(verbose = FALSE)
}

elapsed <- round(difftime(Sys.time(), t_start, units = "mins"), 1)
cat(sprintf(
  "\n-- Loop concluido: %d CSVs, %s linhas em %s min --\n\n",
  total_files, format(total_rows, big.mark = ","), elapsed
))


# -- FASE 6.1: Exportação final para Parquet ---------------------------------
cat("-- FASE 6.1: Exportando tabela_clima -> Parquet (ZSTD) --\n")

if (total_rows == 0) {
  cat("  WARN: Nenhum dado ingerido! Pulando export.\n\n")
  dbDisconnect(con, shutdown = TRUE)
} else {
  if (file.exists(PARQUET_HISTORICO)) file.remove(PARQUET_HISTORICO)

  dbExecute(con, glue(
    "COPY tabela_clima TO '{PARQUET_HISTORICO}'
     (FORMAT PARQUET, COMPRESSION ZSTD, ROW_GROUP_SIZE 100000)"
  ))

  parquet_mb <- round(file.size(PARQUET_HISTORICO) / 1e6, 1)
  cat("  OK: Parquet gerado:", PARQUET_HISTORICO, "(", parquet_mb, "MB )\n\n")
  dbDisconnect(con, shutdown = TRUE)
}


# -- FASE 6.2: Limpeza DuckDB temporário ----------------------------------
cat("-- FASE 6.2: Limpeza de arquivos temporarios --\n")
temp_files <- list.files(BASE_DIR, pattern = "inmet_temp\\.duckdb", full.names = TRUE)
if (length(temp_files) > 0) {
  file.remove(temp_files)
  cat("  Removidos", length(temp_files), "arquivo(s) temporarios.\n\n")
} else {
  cat("  Nenhum temporario a limpar.\n\n")
}


# -- FASE 7: Validação ----------------------------------------------------
if (file.exists(PARQUET_HISTORICO)) {
  cat("-- FASE 7: Validacao do Parquet final --\n")

  con <- dbConnect(duckdb())

  n_rows <- dbGetQuery(con, glue(
    "SELECT count(*) AS n FROM read_parquet('{PARQUET_HISTORICO}')"
  ))$n

  n_stations <- dbGetQuery(con, glue(
    "SELECT count(DISTINCT cd_estacao) AS n FROM read_parquet('{PARQUET_HISTORICO}')"
  ))$n

  span <- dbGetQuery(con, glue(
    "SELECT min(data) AS data_min, max(data) AS data_max
     FROM read_parquet('{PARQUET_HISTORICO}')"
  ))

  cat(sprintf("  Parquet: %s\n", PARQUET_HISTORICO))
  cat(sprintf("  Linhas:   %s\n", format(n_rows, big.mark = ",")))
  cat(sprintf("  Estacoes: %d\n", n_stations))
  cat(sprintf("  Periodo:  %s -> %s\n", span$data_min, span$data_max))
  cat(sprintf("  Tamanho:  %.1f MB\n\n", file.size(PARQUET_HISTORICO) / 1e6))

  # Benchmark query
  sample_station <- dbGetQuery(con, glue(
    "SELECT cd_estacao FROM read_parquet('{PARQUET_HISTORICO}') LIMIT 1"
  ))$cd_estacao

  bench <- system.time({
    result <- dbGetQuery(con, glue(
      "SELECT * FROM read_parquet('{PARQUET_HISTORICO}')
       WHERE cd_estacao = '{sample_station}' ORDER BY data"
    ))
  })
  cat(sprintf("  Benchmark: estacao %s -> %d linhas em %.3fs\n\n",
              sample_station, nrow(result), bench["elapsed"]))

  # Schema
  schema <- dbGetQuery(con, glue(
    "DESCRIBE SELECT * FROM read_parquet('{PARQUET_HISTORICO}')"
  ))
  cat("  Schema do Parquet:\n")
  print(schema)

  dbDisconnect(con, shutdown = TRUE)
} else {
  cat("-- FASE 7: PULADA (sem Parquet gerado) --\n")
}

cat("\n====================================================\n")
cat("  Pipeline concluido!\n")
cat("====================================================\n")
