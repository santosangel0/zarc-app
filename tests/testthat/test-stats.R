# nolint start: commented_code_linter
# tests / testthat / test-stats.R
# Unit tests for app/logic/stats.R
# nolint end

box::use(
  app / logic / stats,
)

describe("compute_summary()", {
  it("returns correct stats for known data", {
    x <- c(10, 20, 30, 40, 50)
    s <- stats$compute_summary(x)

    expect_s3_class(s, "data.frame")
    expect_equal(nrow(s), 1L)
    expect_equal(s$media, 30)
    expect_equal(s$mediana, 30)
    expect_equal(s$minimo, 10)
    expect_equal(s$maximo, 50)
    expect_equal(s$n, 5L)
    expect_true(s$desvio_padrao > 0)
    expect_true(s$variancia > 0)
    expect_true(s$iqr > 0)
  })

  it("ignores NA values", {
    x <- c(10, NA, 30, NA, 50)
    s <- stats$compute_summary(x)
    expect_equal(s$n, 3L)
    expect_equal(s$media, 30)
  })

  it("handles single value", {
    s <- stats$compute_summary(100)
    expect_equal(s$n, 1L)
    expect_equal(s$media, 100)
    expect_true(is.na(s$desvio_padrao))
  })
})

describe("test_normality()", {
  it("detects normal data", {
    set.seed(42)
    x <- rnorm(100, mean = 50, sd = 10)
    res <- stats$test_normality(x)

    expect_true(is.list(res))
    expect_true(!is.na(res$statistic))
    expect_true(!is.na(res$p_value))
    expect_true(res$is_normal)
    expect_true(nchar(res$interpretation) > 0)
  })

  it("detects non-normal data", {
    set.seed(42)
    x <- rexp(100, rate = 1)
    res <- stats$test_normality(x)

    expect_false(res$is_normal)
    expect_true(res$p_value < 0.05)
  })

  it("handles insufficient sample", {
    res <- stats$test_normality(c(1, 2))
    expect_true(is.na(res$statistic))
    expect_true(is.na(res$is_normal))
    expect_true(
      grepl("insuficiente", res$interpretation)
    )
  })

  it("handles large samples via subsampling", {
    set.seed(42)
    x <- rnorm(6000)
    res <- stats$test_normality(x)
    expect_true(!is.na(res$statistic))
  })
})
