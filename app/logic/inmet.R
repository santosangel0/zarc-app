# nolint start: commented_code_linter
# zarc-app / app / logic / inmet.R
# Pure business logic for INMET meteorological
# station data: fetching, spatial filtering,
# quality control, and ITU calculation.
# No Shiny reactivity in this file.
# nolint end

box::use(
  httr2,
  jsonlite,
  sf,
)

#' Fetch all automatic INMET stations.
#'
#' Retrieves the full list of automatic weather
#' stations from the INMET API, cleans coordinates,
#' and returns an `sf` object in SIRGAS 2000.
#'
#' @return An `sf` object with columns
#'   `CD_ESTACAO`, `DC_NOME`, `VL_LATITUDE`,
#'   `VL_LONGITUDE`, and point geometry.
#' @export
get_stations <- function() {
  url <- paste0(
    "https://apitempo.inmet.gov.br/",
    "estacoes/T"
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

  # Drop rows with missing coordinates
  has_coords <- (
    !is.na(data$VL_LATITUDE) &
      !is.na(data$VL_LONGITUDE)
  )
  data <- data[has_coords, ]

  # Coerce to numeric
  data$VL_LATITUDE <- as.numeric(
    data$VL_LATITUDE
  )
  data$VL_LONGITUDE <- as.numeric(
    data$VL_LONGITUDE
  )

  # Drop rows where coercion failed
  valid <- (
    !is.na(data$VL_LATITUDE) &
      !is.na(data$VL_LONGITUDE)
  )
  data <- data[valid, ]

  # Convert to sf (SIRGAS 2000 = EPSG:4674)
  stations_sf <- sf$st_as_sf(
    data,
    coords = c(
      "VL_LONGITUDE", "VL_LATITUDE"
    ),
    crs = 4674L,
    remove = FALSE
  )

  stations_sf
}

#' Filter stations by Region of Interest.
#'
#' Performs a spatial intersection to keep only
#' stations that fall within the ROI polygon.
#'
#' @param stations_sf An `sf` object of stations.
#' @param roi_sf An `sf` polygon for the region.
#' @return An `sf` object with filtered stations.
#' @export
filter_stations <- function(
  stations_sf, roi_sf
) {
  # Ensure matching CRS
  if (
    sf$st_crs(stations_sf) !=
      sf$st_crs(roi_sf)
  ) {
    roi_sf <- sf$st_transform(
      roi_sf,
      sf$st_crs(stations_sf)
    )
  }

  # Spatial join (inner)
  joined <- suppressMessages(
    sf$st_join(
      stations_sf, roi_sf,
      join = sf$st_intersects,
      left = FALSE
    )
  )

  joined
}

#' Fetch daily climate data for a station.
#'
#' Retrieves daily observations from the INMET
#' authenticated API, applies Quality Control
#' filters, and calculates ITU (Buffington 1977).
#'
#' @param station_code Character station code.
#' @param start_date Character or Date start.
#' @param end_date Character or Date end.
#' @return A data.frame with columns: `date`,
#'   `station_code`, `TEMP_MED`, `TEMP_MAX`,
#'   `UMID_MED`, `UMID_MIN`, `ITU_MED`,
#'   `ITU_MAX`.
#' @export
fetch_climate_data <- function(
  station_code, start_date, end_date
) {
  token <- config::get("inmet_token")

  url <- paste0(
    "https://apitempo.inmet.gov.br/",
    "token/estacao/diaria/",
    start_date, "/", end_date, "/",
    station_code, "/", token
  )

  resp <- httr2$request(url) |>
    httr2$req_retry(max_tries = 3L) |>
    httr2$req_timeout(120L) |>
    httr2$req_error(
      is_error = function(resp) FALSE
    ) |>
    httr2$req_perform()

  data <- httr2$resp_body_json(
    resp,
    simplifyVector = TRUE
  )

  # Empty columns definition
  empty_df <- data.frame(
    date = as.Date(character(0)),
    station_code = character(0),
    TEMP_MED = numeric(0),
    TEMP_MAX = numeric(0),
    UMID_MED = numeric(0),
    UMID_MIN = numeric(0),
    ITU_MED = numeric(0),
    ITU_MAX = numeric(0),
    stringsAsFactors = FALSE
  )

  if (
    length(data) == 0L ||
      !is.data.frame(data) ||
      nrow(data) == 0L
  ) {
    return(empty_df)
  }

  # Build result data.frame
  df <- data.frame(
    date = as.Date(data$DT_MEDICAO),
    station_code = station_code,
    stringsAsFactors = FALSE
  )

  # Coerce numeric columns
  df$TEMP_MED <- suppressWarnings(
    as.numeric(data$TEMP_MED)
  )
  df$TEMP_MAX <- suppressWarnings(
    as.numeric(data$TEMP_MAX)
  )
  df$UMID_MED <- suppressWarnings(
    as.numeric(data$UMID_MED)
  )
  df$UMID_MIN <- suppressWarnings(
    as.numeric(data$UMID_MIN)
  )

  # ── Quality Control ──
  # Temperature: [-10, 50]
  df$TEMP_MED <- ifelse(
    df$TEMP_MED < -10 | df$TEMP_MED > 50,
    NA_real_,
    df$TEMP_MED
  )
  df$TEMP_MAX <- ifelse(
    df$TEMP_MAX < -10 | df$TEMP_MAX > 50,
    NA_real_,
    df$TEMP_MAX
  )

  # Humidity: [0, 100]
  df$UMID_MED <- ifelse(
    df$UMID_MED < 0 | df$UMID_MED > 100,
    NA_real_,
    df$UMID_MED
  )
  df$UMID_MIN <- ifelse(
    df$UMID_MIN < 0 | df$UMID_MIN > 100,
    NA_real_,
    df$UMID_MIN
  )

  # ── ITU Calculation (Buffington 1977) ──
  # ITU = 0.8*Tbs + UR*(Tbs - 14.3)/100 + 46.3
  df$ITU_MED <- (
    0.8 * df$TEMP_MED +
      (df$UMID_MED *
        (df$TEMP_MED - 14.3)) / 100 +
      46.3
  )

  df$ITU_MAX <- (
    0.8 * df$TEMP_MAX +
      (df$UMID_MIN *
        (df$TEMP_MAX - 14.3)) / 100 +
      46.3
  )

  df
}
