# nolint start: commented_code_linter
# zarc-app / app / logic / stats.R
# Funções auxiliares de estatística para dados leiteiros.
# nolint end

#' Calcula estatísticas sumárias para um vetor numérico.
#'
#' @param x Vetor numérico de valores.
#' @return data.frame com uma linha e colunas:
#'   `media`, `mediana`, `desvio_padrao`,
#'   `variancia`, `iqr`, `minimo`, `maximo`, `n`.
#' @export
compute_summary <- function(x) {
  x <- x[!is.na(x)]
  data.frame(
    media = mean(x),
    mediana = stats::median(x),
    desvio_padrao = stats::sd(x),
    variancia = stats::var(x),
    iqr = stats::IQR(x),
    minimo = min(x),
    maximo = max(x),
    n = length(x),
    stringsAsFactors = FALSE
  )
}

#' Executa teste de normalidade de Shapiro-Wilk.
#'
#' Retorna resultados do teste mais interpretação em pt-br.
#' Trata casos especiais (n < 3, n > 5000).
#'
#' @param x Vetor numérico de valores.
#' @param alpha Nível de significância (padrão 0.05).
#' @return Lista com `statistic`, `p_value`,
#'   `is_normal` e `interpretation`.
#' @export
test_normality <- function(x, alpha = 0.05) {
  x <- x[!is.na(x)]
  n <- length(x)

  if (n < 3L) {
    return(list(
      statistic = NA_real_,
      p_value = NA_real_,
      is_normal = NA,
      interpretation = paste0(
        "N\u00e3o \u00e9 poss\u00edvel ",
        "realizar o teste de ",
        "normalidade: amostra ",
        "insuficiente (n=", n, ", ",
        "m\u00ednimo=3)."
      )
    ))
  }

  # Shapiro-Wilk supports n <= 5000
  test_x <- if (n > 5000L) {
    sample(x, 5000L)
  } else {
    x
  }

  result <- stats::shapiro.test(test_x)
  p <- result$p.value
  w <- result$statistic

  is_normal <- p >= alpha

  if (is_normal) {
    interp <- paste0(
      "Os dados seguem uma ",
      "distribui\u00e7\u00e3o normal ",
      "(W=", round(w, 4),
      ", p-valor=",
      format(p, digits = 4),
      "). N\u00e3o h\u00e1 ",
      "evid\u00eancia suficiente ",
      "para rejeitar a hip\u00f3tese ",
      "de normalidade ao n\u00edvel ",
      "de ", alpha * 100, "%."
    )
  } else {
    interp <- paste0(
      "Os dados N\u00c3O seguem ",
      "uma distribui\u00e7\u00e3o ",
      "normal (W=", round(w, 4),
      ", p-valor=",
      format(p, digits = 4),
      "). A hip\u00f3tese de ",
      "normalidade foi ",
      "rejeitada ao n\u00edvel ",
      "de ", alpha * 100, "%."
    )
  }

  list(
    statistic = unname(w),
    p_value = p,
    is_normal = is_normal,
    interpretation = interp
  )
}
