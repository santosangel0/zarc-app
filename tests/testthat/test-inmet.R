box::use(
  testthat[
    describe, it, expect_true, expect_type,
    expect_s3_class, expect_equal,
    expect_length, expect_named
  ],
  webmockr[
    enable, disable,
    stub_request, to_return
  ],
  sf,
  app / logic / inmet,
)

# ── Dados Mock ──────────────────────────────────

mock_stations_json <- paste0(
  "[",
  "{\"CD_ESTACAO\":\"A001\",",
  "\"DC_NOME\":\"GOIANIA\",",
  "\"VL_LATITUDE\":\"-16.64\",",
  "\"VL_LONGITUDE\":\"-49.22\",",
  "\"SG_ESTADO\":\"GO\"},",
  "{\"CD_ESTACAO\":\"A002\",",
  "\"DC_NOME\":\"MANAUS\",",
  "\"VL_LATITUDE\":\"-3.10\",",
  "\"VL_LONGITUDE\":\"-60.02\",",
  "\"SG_ESTADO\":\"AM\"},",
  "{\"CD_ESTACAO\":\"A003\",",
  "\"DC_NOME\":\"BAD_COORDS\",",
  "\"VL_LATITUDE\":null,",
  "\"VL_LONGITUDE\":null,",
  "\"SG_ESTADO\":\"XX\"}",
  "]"
)

# Sample daily data with edge cases:
#   Day 1: normal values
#   Day 2: TEMP_MED=55 (out of range), UMID_MIN=-5
#   Day 3: normal values for ITU validation
mock_climate_json <- paste0(
  "[",
  "{\"DT_MEDICAO\":\"2023-01-01\",",
  "\"TEMP_MED\":\"25.0\",",
  "\"TEMP_MAX\":\"30.0\",",
  "\"UMID_MED\":\"70\",",
  "\"UMID_MIN\":\"50\"},",
  "{\"DT_MEDICAO\":\"2023-01-02\",",
  "\"TEMP_MED\":\"55.0\",",
  "\"TEMP_MAX\":\"28.0\",",
  "\"UMID_MED\":\"65\",",
  "\"UMID_MIN\":\"-5\"},",
  "{\"DT_MEDICAO\":\"2023-01-03\",",
  "\"TEMP_MED\":\"20.0\",",
  "\"TEMP_MAX\":\"26.0\",",
  "\"UMID_MED\":\"80\",",
  "\"UMID_MIN\":\"60\"}",
  "]"
)

mock_climate_empty_json <- "[]"

# ── Ativa mocking ───────────────────────────────

enable(quiet = TRUE)
withr::defer(disable(quiet = TRUE))

inmet_base <- (
  "https://apitempo.inmet.gov.br"
)

# Stub: lista de estações
stub_request(
  "get",
  paste0(inmet_base, "/estacoes/T")
) |>
  to_return(
    body = mock_stations_json,
    status = 200L,
    headers = list(
      "Content-Type" = "application/json"
    )
  )

# Stub: dados climáticos diários (normal)
stub_request(
  "get",
  paste0(
    inmet_base,
    "/token/estacao/diaria/",
    "2023-01-01/2023-01-03/",
    "A001/TEST_TOKEN"
  )
) |>
  to_return(
    body = mock_climate_json,
    status = 200L,
    headers = list(
      "Content-Type" = "application/json"
    )
  )

# Stub: dados climáticos diários (vazio)
stub_request(
  "get",
  paste0(
    inmet_base,
    "/token/estacao/diaria/",
    "2023-06-01/2023-06-30/",
    "A999/TEST_TOKEN"
  )
) |>
  to_return(
    body = mock_climate_empty_json,
    status = 200L,
    headers = list(
      "Content-Type" = "application/json"
    )
  )

# ── Testes ───────────────────────────────────────

describe("Token security", {
  it("config retrieves inmet_token from env", {
    # Set env var for test
    withr::local_envvar(
      INMET_TOKEN = "TEST_TOKEN"
    )
    token <- config::get("inmet_token")
    expect_type(token, "character")
    expect_true(nchar(token) > 0L)
  })

  it("token is NOT hardcoded in inmet.R", {
    # Resolve path from project root
    inmet_path <- file.path(
      rprojroot::find_root(
        rprojroot::has_file("rhino.yml")
      ),
      "app", "logic", "inmet.R"
    )
    src <- readLines(
      inmet_path,
      warn = FALSE
    )
    combined <- paste(src, collapse = "\n")
    # Should not contain any literal token
    expect_true(
      !grepl(
        "TEST_TOKEN", combined,
        fixed = TRUE
      )
    )
    # Should reference config::get
    expect_true(
      grepl(
        "config", combined,
        fixed = TRUE
      )
    )
  })
})

describe("get_stations()", {
  it("returns an sf object", {
    stations <- inmet$get_stations()
    expect_s3_class(stations, "sf")
  })

  it("has required columns", {
    stations <- inmet$get_stations()
    expected <- c(
      "CD_ESTACAO", "DC_NOME",
      "VL_LATITUDE", "VL_LONGITUDE"
    )
    for (col in expected) {
      expect_true(
        col %in% names(stations),
        info = paste("Missing:", col)
      )
    }
  })

  it("drops rows with missing coords", {
    stations <- inmet$get_stations()
    # Mock tem 3 estações, 1 com coordenadas nulas
    expect_equal(nrow(stations), 2L)
  })

  it("uses WGS84 CRS", {
    stations <- inmet$get_stations()
    crs_code <- sf$st_crs(stations)$epsg
    expect_equal(crs_code, 4326L)
  })
})

describe("filter_stations()", {
  it("returns only stations within ROI", {
    stations <- inmet$get_stations()

    # ROI polygon covering Goiania area
    roi <- sf$st_sf(
      geometry = sf$st_sfc(
        sf$st_polygon(list(rbind(
          c(-50.0, -17.0),
          c(-48.0, -17.0),
          c(-48.0, -16.0),
          c(-50.0, -16.0),
          c(-50.0, -17.0)
        ))),
        crs = 4326L
      )
    )

    filtered <- inmet$filter_stations(
      stations, roi
    )
    expect_s3_class(filtered, "sf")
    # Only GOIANIA (A001) is inside
    expect_equal(nrow(filtered), 1L)
    expect_equal(
      filtered$CD_ESTACAO[1L], "A001"
    )
  })

  it("returns empty sf for non-overlapping", {
    stations <- inmet$get_stations()

    # ROI far from any station
    roi <- sf$st_sf(
      geometry = sf$st_sfc(
        sf$st_polygon(list(rbind(
          c(0.0, 0.0),
          c(1.0, 0.0),
          c(1.0, 1.0),
          c(0.0, 1.0),
          c(0.0, 0.0)
        ))),
        crs = 4326L
      )
    )

    filtered <- inmet$filter_stations(
      stations, roi
    )
    expect_s3_class(filtered, "sf")
    expect_equal(nrow(filtered), 0L)
  })
})

describe("fetch_climate_data()", {
  it("returns a data.frame", {
    withr::local_envvar(
      INMET_TOKEN = "TEST_TOKEN"
    )
    result <- inmet$fetch_climate_data(
      "A001", "2023-01-01", "2023-01-03"
    )
    expect_s3_class(result, "data.frame")
  })

  it("has expected columns", {
    withr::local_envvar(
      INMET_TOKEN = "TEST_TOKEN"
    )
    result <- inmet$fetch_climate_data(
      "A001", "2023-01-01", "2023-01-03"
    )
    expected <- c(
      "date", "station_code",
      "TEMP_MED", "TEMP_MAX",
      "UMID_MED", "UMID_MIN",
      "ITU_MED", "ITU_MAX"
    )
    for (col in expected) {
      expect_true(
        col %in% names(result),
        info = paste("Missing:", col)
      )
    }
  })

  it("applies QC: out-of-range temp -> NA", {
    withr::local_envvar(
      INMET_TOKEN = "TEST_TOKEN"
    )
    result <- inmet$fetch_climate_data(
      "A001", "2023-01-01", "2023-01-03"
    )
    # Day 2: TEMP_MED=55 is out of [-10,50]
    row2 <- result[
      result$date == as.Date("2023-01-02"),
    ]
    expect_true(is.na(row2$TEMP_MED))
  })

  it("applies QC: out-of-range humidity -> NA", {
    withr::local_envvar(
      INMET_TOKEN = "TEST_TOKEN"
    )
    result <- inmet$fetch_climate_data(
      "A001", "2023-01-01", "2023-01-03"
    )
    # Day 2: UMID_MIN=-5 is out of [0,100]
    row2 <- result[
      result$date == as.Date("2023-01-02"),
    ]
    expect_true(is.na(row2$UMID_MIN))
  })

  it("calculates ITU correctly (Buffington)", {
    withr::local_envvar(
      INMET_TOKEN = "TEST_TOKEN"
    )
    result <- inmet$fetch_climate_data(
      "A001", "2023-01-01", "2023-01-03"
    )
    # Day 1: TEMP_MED=25, UMID_MED=70
    row1 <- result[
      result$date == as.Date("2023-01-01"),
    ]
    expected_itu_med <- (
      0.8 * 25 +
        (70 * (25 - 14.3)) / 100 +
        46.3
    )
    expect_equal(
      row1$ITU_MED,
      expected_itu_med,
      tolerance = 0.01
    )

    # Day 1: TEMP_MAX=30, UMID_MIN=50
    expected_itu_max <- (
      0.8 * 30 +
        (50 * (30 - 14.3)) / 100 +
        46.3
    )
    expect_equal(
      row1$ITU_MAX,
      expected_itu_max,
      tolerance = 0.01
    )
  })

  it("ITU is NA when QC nullifies inputs", {
    withr::local_envvar(
      INMET_TOKEN = "TEST_TOKEN"
    )
    result <- inmet$fetch_climate_data(
      "A001", "2023-01-01", "2023-01-03"
    )
    # Day 2: TEMP_MED was set to NA by QC
    row2 <- result[
      result$date == as.Date("2023-01-02"),
    ]
    expect_true(is.na(row2$ITU_MED))
    # Day 2: UMID_MIN was set to NA by QC
    expect_true(is.na(row2$ITU_MAX))
  })

  it("returns empty df for empty API response", {
    withr::local_envvar(
      INMET_TOKEN = "TEST_TOKEN"
    )
    result <- inmet$fetch_climate_data(
      "A999", "2023-06-01", "2023-06-30"
    )
    expect_s3_class(result, "data.frame")
    expect_equal(nrow(result), 0L)
  })
})

describe("buffer_polygon()", {
  it("returns same polygon when buffer is 0", {
    roi <- sf$st_sf(
      geometry = sf$st_sfc(
        sf$st_polygon(list(rbind(
          c(-50.0, -17.0),
          c(-48.0, -17.0),
          c(-48.0, -16.0),
          c(-50.0, -16.0),
          c(-50.0, -17.0)
        ))),
        crs = 4326L
      )
    )
    result <- inmet$buffer_polygon(roi, 0)
    expect_s3_class(result, "sf")
    expect_equal(
      sf$st_area(result),
      sf$st_area(roi)
    )
  })

  it("returns larger polygon when buffer > 0", {
    roi <- sf$st_sf(
      geometry = sf$st_sfc(
        sf$st_polygon(list(rbind(
          c(-50.0, -17.0),
          c(-48.0, -17.0),
          c(-48.0, -16.0),
          c(-50.0, -16.0),
          c(-50.0, -17.0)
        ))),
        crs = 4326L
      )
    )
    buffered <- inmet$buffer_polygon(roi, 10)
    expect_s3_class(buffered, "sf")
    area_orig <- sf$st_area(roi)
    area_buff <- sf$st_area(buffered)
    expect_true(area_buff > area_orig)
  })

  it("preserves CRS EPSG:4674", {
    roi <- sf$st_sf(
      geometry = sf$st_sfc(
        sf$st_polygon(list(rbind(
          c(-50.0, -17.0),
          c(-48.0, -17.0),
          c(-48.0, -16.0),
          c(-50.0, -16.0),
          c(-50.0, -17.0)
        ))),
        crs = 4326L
      )
    )
    buffered <- inmet$buffer_polygon(roi, 25)
    expect_equal(
      sf$st_crs(buffered)$epsg, 4326L
    )
  })
})
