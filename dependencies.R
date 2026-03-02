# This file allows packrat (used by rsconnect during deployment) to pick up dependencies.
# It is also used by renv to discover project dependencies.

# ── Framework ────────────────────────────────────────────────────────────────
library(rhino)
library(treesitter)
library(treesitter.r)

# ── Shiny / UI ───────────────────────────────────────────────────────────────
library(shiny)
library(bslib)
library(leaflet)

# ── Data & HTTP ──────────────────────────────────────────────────────────────
library(httr2)
library(jsonlite)
library(sf)
library(dplyr)
