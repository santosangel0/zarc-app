# ──────────────────────────────────────────────────────────────────────────────
# zarc-app Dockerfile
# Multi-stage build optimized for Shiny / Rhino applications.
# ──────────────────────────────────────────────────────────────────────────────

# ── Stage 1: Builder ─────────────────────────────────────────────────────────
FROM rocker/r-ver:4.5.2 AS builder

# System dependencies for spatial packages (sf, terra)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgdal-dev \
    libgeos-dev \
    libudunits2-dev \
    libproj-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Restore renv library first (cache-friendly layer)
COPY renv.lock renv.lock
COPY dependencies.R dependencies.R
COPY .Rprofile .Rprofile
COPY renv/ renv/

# Disable renv cache so packages are installed directly into renv/library/
# instead of as symlinks (which break across multi-stage COPY).
ENV RENV_CONFIG_CACHE_ENABLED=FALSE

RUN Rscript -e "renv::restore(prompt = FALSE)"

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM rocker/r-ver:4.5.2 AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgdal-dev \
    libgeos-dev \
    libudunits2-dev \
    libproj-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy restored renv library from builder
COPY --from=builder /build/renv/ renv/
COPY --from=builder /build/renv.lock renv.lock
COPY --from=builder /build/.Rprofile .Rprofile

# Copy application code
COPY app.R app.R
COPY config.yml config.yml
COPY dependencies.R dependencies.R
COPY rhino.yml rhino.yml
COPY app/ app/

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('.', host = '0.0.0.0', port = 3838)"]
