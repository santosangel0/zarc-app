box::use(
  testthat[
    describe, it, expect_true, expect_type,
    expect_length, expect_s3_class, expect_error
  ],
  app / logic / ibge,
)

describe("get_regions()", {
  it("returns a named list of 5 macro-regions", {
    regions <- ibge$get_regions()
    expect_type(regions, "list")
    expect_length(regions, 5)
    expected <- c(
      "Norte", "Nordeste", "Sudeste",
      "Sul", "Centro-Oeste"
    )
    for (nm in expected) {
      expect_true(nm %in% names(regions))
    }
  })

  it("returns integer codes", {
    regions <- ibge$get_regions()
    for (code in regions) {
      expect_type(code, "integer")
    }
  })
})

describe("get_states()", {
  it("returns states for Centro-Oeste", {
    states <- ibge$get_states(5L)
    expect_s3_class(states, "data.frame")
    expect_true("id" %in% names(states))
    expect_true("nome" %in% names(states))
    expect_true(nrow(states) >= 3L)
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

describe("fetch_geojson()", {
  it("returns an sf object for a region", {
    geo <- ibge$fetch_geojson("regioes", 5L)
    expect_s3_class(geo, "sf")
  })

  it("errors on invalid level", {
    expect_error(
      ibge$fetch_geojson("invalid", 1L),
      "Invalid level"
    )
  })
})

describe("fetch_subdivisions()", {
  it("returns sf with subdivisions", {
    geo <- ibge$fetch_subdivisions(
      52L, "mesorregioes"
    )
    expect_s3_class(geo, "sf")
    expect_true(nrow(geo) >= 1L)
  })

  it("errors on invalid subdivision", {
    expect_error(
      ibge$fetch_subdivisions(52L, "bad"),
      "Invalid subdivision_level"
    )
  })
})

describe("fetch_milk_production()", {
  it("returns data for Goias (N3) 2021", {
    milk <- ibge$fetch_milk_production(
      "N3", 52L, 2021L
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
      "N3", 99L, 2021L
    )
    expect_s3_class(milk, "data.frame")
    expect_true(nrow(milk) == 0L)
  })
})
