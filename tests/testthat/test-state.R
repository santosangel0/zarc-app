box::use(
  testthat[
    describe, it, expect_type, expect_true,
    expect_match, expect_error, expect_null,
    expect_s3_class
  ],
  jsonlite,
  shiny[
    testServer, reactiveValues, isolate,
    reactiveValuesToList
  ],
  app / logic / state,
)

describe("create_state()", {
  it("returns reactiveValues with defaults", {
    testServer(
      app = shiny::shinyApp(
        ui = shiny::fluidPage(),
        server = function(input, output, session) {
          st <- state$create_state()
          expect_null(isolate(st$region_code))
          expect_null(isolate(st$state_code))
          expect_null(
            isolate(st$mesoregion_code)
          )
          expect_type(
            isolate(st$year), "integer"
          )
        }
      ),
      expr = {}
    )
  })
})

describe("export/import round-trip", {
  it("round-trips state through JSON", {
    testServer(
      app = shiny::shinyApp(
        ui = shiny::fluidPage(),
        server = function(input, output, session) {
          st <- state$create_state()

          st$region_code <- 5L
          st$region_name <- "Centro-Oeste"
          st$state_code <- 52L
          st$year <- 2022L

          json <- state$export_state(st)
          expect_type(json, "character")
          expect_match(json, "Centro-Oeste")
          expect_match(json, "2022")

          tmp <- tempfile(fileext = ".json")
          on.exit(unlink(tmp), add = TRUE)
          writeLines(json, tmp)

          new_st <- state$create_state()
          state$import_state(new_st, tmp)

          expect_true(
            isolate(new_st$region_code) == 5L
          )
          expect_true(
            isolate(
              new_st$region_name
            ) == "Centro-Oeste"
          )
          expect_true(
            isolate(new_st$state_code) == 52L
          )
          expect_true(
            isolate(new_st$year) == 2022L
          )
          expect_null(
            isolate(new_st$mesoregion_code)
          )
        }
      ),
      expr = {}
    )
  })

  it("erro em arquivo inexistente", {
    expect_error(
      state$import_state(
        NULL, "/nonexistent/file.json"
      ),
      "State file not found"
    )
  })
})
