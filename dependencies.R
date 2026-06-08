# Este arquivo permite que o packrat (usado pelo rsconnect durante deploy) identifique dependências.
# Também é usado pelo renv para descobrir dependências do projeto.

# ── Framework ────────────────────────────────────────────────────────────────
library(rhino)
library(treesitter)
library(treesitter.r)

# ── Shiny / UI ───────────────────────────────────────────────────────────────
library(shiny)
library(bslib)
library(leaflet)

# ── Dados & HTTP ─────────────────────────────────────────────────────────────
library(httr2)
library(jsonlite)
library(sf)
library(dplyr)

# ── Gráficos ─────────────────────────────────────────────────────────────────
library(plotly)
library(ggplot2)
library(DT)

# ── Testes ────────────────────────────────────────────────────────────────────
library(webmockr)
