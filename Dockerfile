# ──────────────────────────────────────────────────────────────────────────────
# zarc-app Dockerfile
# Build multi-estágio otimizado para aplicações Shiny / Rhino.
# ──────────────────────────────────────────────────────────────────────────────

# ── Estágio 1: Builder ───────────────────────────────────────────────────────
FROM rocker/r-ver:4.5.2 AS builder

# Dependências do sistema para pacotes espaciais (sf, terra)
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

# Restaura biblioteca renv primeiro (camada cache-friendly)
COPY renv.lock renv.lock
COPY dependencies.R dependencies.R
COPY .Rprofile .Rprofile
COPY renv/ renv/

# Desabilita cache do renv para instalar pacotes diretamente em renv/library/
# em vez de symlinks (quebram em COPY multi-estágio).
ENV RENV_CONFIG_CACHE_ENABLED=FALSE

RUN Rscript -e "renv::restore(prompt = FALSE)"

# ── Estágio 2: Runtime ───────────────────────────────────────────────────────
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

# Copia biblioteca renv restaurada do builder
COPY --from=builder /build/renv/ renv/
COPY --from=builder /build/renv.lock renv.lock
COPY --from=builder /build/.Rprofile .Rprofile

# Copia código da aplicação
COPY app.R app.R
COPY config.yml config.yml
COPY dependencies.R dependencies.R
COPY rhino.yml rhino.yml
COPY app/ app/

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('.', host = '0.0.0.0', port = 3838)"]
