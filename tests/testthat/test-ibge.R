box::use(
  testthat[
    describe, it, expect_true, expect_type,
    expect_length, expect_s3_class, expect_error,
    expect_equal, expect_warning
  ],
  webmockr[
    enable, disable,
    stub_request, to_return, wi_th
  ],
  app / logic / ibge,
)

# ── Mock Data ────────────────────────────────────

mock_states_json <- paste0(
  "[",
  "{\"id\":52,\"sigla\":\"GO\",",
  "\"nome\":\"Goi\\u00e1s\"},",
  "{\"id\":31,\"sigla\":\"MG\",",
  "\"nome\":\"Minas Gerais\"}",
  "]"
)

mock_meso_json <- paste0(
  "[",
  "{\"id\":5201,\"nome\":\"Noroeste\"},",
  "{\"id\":5202,\"nome\":\"Norte\"}",
  "]"
)

mock_micro_json <- paste0(
  "[",
  "{\"id\":52001,\"nome\":\"Porangatu\"},",
  "{\"id\":52002,\"nome\":\"Rio Vermelho\"}",
  "]"
)

mock_munic_json <- paste0(
  "[",
  "{\"id\":5200050,\"nome\":\"Abadia\"},",
  "{\"id\":5200100,\"nome\":\"Abadiania\"}",
  "]"
)

mock_all_states_json <- paste0(
  "[",
  "{\"id\":12,\"nome\":\"Acre\"},",
  "{\"id\":27,\"nome\":\"Alagoas\"},",
  "{\"id\":52,\"nome\":\"Goi\\u00e1s\"}",
  "]"
)

mock_milk_json <- paste0(
  "[",
  "{\"id\":\"t1086\",\"variavel\":",
  "\"Leite\",\"unidade\":\"Mil litros\",",
  "\"resultados\":[{\"classificacoes\"",
  ":[],\"series\":[",
  "{\"localidade\":{\"id\":\"52\",",
  "\"nome\":\"Goi\\u00e1s\",",
  "\"nivel\":{\"id\":\"N3\"}},",
  "\"serie\":{\"2021\":\"3619092\"}}",
  "]}]}",
  "]"
)

mock_milk_empty_json <- paste0(
  "[",
  "{\"id\":\"t1086\",\"variavel\":",
  "\"Leite\",\"unidade\":\"Mil litros\",",
  "\"resultados\":[{\"classificacoes\"",
  ":[],\"series\":[]}]}",
  "]"
)

# ── Enable mocking ───────────────────────────────

enable(quiet = TRUE)

withr::defer(disable(quiet = TRUE))

base_url <- paste0(
  "https://servicodados.ibge.gov.br"
)

# Stub: get_states for region 5
stub_request(
  "get",
  paste0(
    base_url,
    "/api/v1/localidades/regioes/",
    "5/estados"
  )
) |>
  to_return(
    body = mock_states_json,
    status = 200L,
    headers = list(
      "Content-Type" = "application/json"
    )
  )

# Stub: get_all_states
stub_request(
  "get",
  paste0(
    base_url,
    "/api/v1/localidades/estados",
    "?orderBy=nome"
  )
) |>
  to_return(
    body = mock_all_states_json,
    status = 200L,
    headers = list(
      "Content-Type" = "application/json"
    )
  )

# Stub: get_mesoregions for state 52
stub_request(
  "get",
  paste0(
    base_url,
    "/api/v1/localidades/estados/",
    "52/mesorregioes"
  )
) |>
  to_return(
    body = mock_meso_json,
    status = 200L,
    headers = list(
      "Content-Type" = "application/json"
    )
  )

# Stub: get_microregions for state 52
stub_request(
  "get",
  paste0(
    base_url,
    "/api/v1/localidades/estados/",
    "52/microrregioes"
  )
) |>
  to_return(
    body = mock_micro_json,
    status = 200L,
    headers = list(
      "Content-Type" = "application/json"
    )
  )

# Stub: get_municipalities for state 52
stub_request(
  "get",
  paste0(
    base_url,
    "/api/v1/localidades/estados/",
    "52/municipios?orderBy=nome"
  )
) |>
  to_return(
    body = mock_munic_json,
    status = 200L,
    headers = list(
      "Content-Type" = "application/json"
    )
  )

# Stub: fetch_milk_production N3 52 2021
stub_request(
  "get",
  paste0(
    base_url,
    "/api/v3/agregados/74/periodos/",
    "2021/variaveis/106",
    "?localidades=N3[52]",
    "&classificacao=80[2682]"
  )
) |>
  to_return(
    body = mock_milk_json,
    status = 200L,
    headers = list(
      "Content-Type" = "application/json"
    )
  )

# Stub: fetch_milk_production N3 99 (bad)
stub_request(
  "get",
  paste0(
    base_url,
    "/api/v3/agregados/74/periodos/",
    "2021/variaveis/106",
    "?localidades=N3[99]",
    "&classificacao=80[2682]"
  )
) |>
  to_return(
    body = mock_milk_empty_json,
    status = 200L,
    headers = list(
      "Content-Type" = "application/json"
    )
  )

# ── Tests ────────────────────────────────────────

describe("get_regions()", {
  it("returns 5 macro-regions", {
    regions <- ibge$get_regions()
    expect_type(regions, "list")
    expect_length(regions, 5L)
    expect_true("Norte" %in% names(regions))
    expect_true("Sul" %in% names(regions))
  })
})

describe("get_states()", {
  it("returns states for Centro-Oeste", {
    states <- ibge$get_states(5L)
    expect_s3_class(states, "data.frame")
    expect_true("id" %in% names(states))
    expect_true("nome" %in% names(states))
    expect_true(52L %in% states$id)
  })
})

describe("get_all_states()", {
  it("returns all states", {
    states <- ibge$get_all_states()
    expect_s3_class(states, "data.frame")
    expect_true("id" %in% names(states))
    expect_true(nrow(states) >= 1L)
  })
})

describe("get_mesoregions()", {
  it("returns mesoregions for Goias", {
    mesos <- ibge$get_mesoregions(52L)
    expect_s3_class(mesos, "data.frame")
    expect_true("id" %in% names(mesos))
    expect_true("nome" %in% names(mesos))
    expect_true(nrow(mesos) >= 1L)
  })
})

describe("get_microregions()", {
  it("returns microregions for Goias", {
    micros <- ibge$get_microregions(52L)
    expect_s3_class(micros, "data.frame")
    expect_true("id" %in% names(micros))
    expect_true("nome" %in% names(micros))
    expect_true(nrow(micros) >= 1L)
  })
})

describe("get_municipalities()", {
  it("returns municipalities for Goias", {
    munis <- ibge$get_municipalities(52L)
    expect_s3_class(munis, "data.frame")
    expect_true("id" %in% names(munis))
    expect_true("nome" %in% names(munis))
    expect_true(nrow(munis) >= 1L)
  })
})

describe("fetch_milk_production()", {
  it("returns data for Goias (N3) 2021", {
    milk <- ibge$fetch_milk_production(
      "N3", 52L, c(2021L)
    )
    expect_s3_class(milk, "data.frame")
    expected_cols <- c(
      "code", "nome",
      "year", "milk_production_liters"
    )
    for (col in expected_cols) {
      expect_true(
        col %in% names(milk),
        info = paste("Missing:", col)
      )
    }
    expect_true(nrow(milk) > 0L)
  })

  it("returns empty df for bad territory", {
    milk <- ibge$fetch_milk_production(
      "N3", 99L, c(2021L)
    )
    expect_s3_class(milk, "data.frame")
    expect_true(nrow(milk) == 0L)
  })
})

describe("validate_api_request()", {
  it("returns TRUE for small requests", {
    result <- ibge$validate_api_request(
      n_categories = 1L,
      n_periods = 10L,
      n_locations = 50L
    )
    expect_true(result)
  })

  it("returns error message for large", {
    result <- ibge$validate_api_request(
      n_categories = 1L,
      n_periods = 50L,
      n_locations = 5000L
    )
    expect_type(result, "character")
    expect_true(
      grepl("100.000", result)
    )
  })

  it("boundary: exactly 100000 is valid", {
    result <- ibge$validate_api_request(
      n_categories = 1L,
      n_periods = 100L,
      n_locations = 1000L
    )
    expect_true(result)
  })
})

describe("clean_sidra_values()", {
  it("converts dash to 0", {
    expect_equal(
      ibge$clean_sidra_values("-"), 0
    )
  })

  it("converts dots and X to NA", {
    result <- ibge$clean_sidra_values(
      c("..", "...", "X")
    )
    expect_true(all(is.na(result)))
  })

  it("parses numeric strings", {
    expect_equal(
      ibge$clean_sidra_values(
        c("100", "200", "300")
      ),
      c(100, 200, 300)
    )
  })

  it("handles mixed values", {
    result <- ibge$clean_sidra_values(
      c("100", "-", "..", "50")
    )
    expect_equal(result, c(100, 0, NA, 50))
  })
})
