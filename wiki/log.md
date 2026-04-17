# Wiki Log

Chronological record of all wiki operations.

---

## [2026-04-15] init | Wiki created

Initialized the ZARC research wiki with schema (`CLAUDE.md`), index, log, and directory structure. Domain: agricultural zoning for climate risk, focused on dairy farming in Brazil. Ready for first source ingest.

## [2026-04-15] schema-update | Added app documentation scope

Expanded wiki scope to include zarc-app technical internals: pipelines, architecture, data handling, deployment. Added `pages/app/` directory, `app` page type, `ingest-from-code` workflow, and app-related tags to the schema.

## [2026-04-15] ingest | Andrade et al. (2023) — THI Maps for SE Brazil

Source: `raw/assets/ART+050_BJAER_JAN_2023.pdf` (DOI: 10.34188/bjaerv6n1-050)

Pages created (7):
- `pages/sources/andrade-2023-thi-maps-southeast-brazil.md` — full source summary with bibliographic metadata and citation table
- `pages/concepts/thi-temperature-humidity-index.md` — THI formula, thresholds, limitations
- `pages/concepts/thermal-stress-dairy.md` — breed-dependent thermoneutral zones, production impact
- `pages/concepts/idw-interpolation.md` — spatial interpolation method used in the study
- `pages/entities/embrapa.md` — EMBRAPA institution page, GeoInfo platform
- `pages/entities/inmet.md` — INMET station network, data characteristics
- `pages/entities/ibge-ppm.md` — Municipal Livestock Survey, milk production data via SIDRA

## [2026-04-17] ingest | Batch ingest — 5 new sources

Sources ingested:
1. `raw/assets/Dairy farming and climate parameters.pdf` — Dias-Souza et al. (2026), DOI: 10.29374/2527-2179.bjvm008525
2. `raw/assets/Impact of Heat Stress on Milk Yield.pdf` — Boonkum et al. (2024), DOI: 10.3390/ani14203026
3. `raw/assets/Resumo_Expandido_Pamella_Silva_Atualizado_14_08_25.pdf` — Silva et al. (2025), EMBRAPA/UFJF
4. `raw/assets/AVALIAÇÃO DO ÍNDICE DE VEGETAÇÃO PADRONIZADO.pdf` — Leivas et al. (2014), Rev. Bras. Cartografia
5. `raw/assets/Estimativa-espacializacao.pdf` — THI spatialization for MG (limited text extraction)

Pages created (9):
- `pages/sources/dias-souza-2026-dairy-climate-minas-gerais.md` — precipitation as dominant climate driver; 12 high-productivity MG cities
- `pages/sources/boonkum-2024-heat-stress-thai-holstein.md` — THI=76 threshold; genetic parameters; breed group analysis
- `pages/sources/silva-2025-drought-indices-paracatu.md` — SPI/SPEI vs NDVI; 6-month SPI best (r=0.89)
- `pages/sources/leivas-2014-svi-drought-soybean-south-brazil.md` — SVI drought monitoring; SPOT-Vegetation; soybean South Brazil
- `pages/sources/estimativa-espacializacao-thi-minas-gerais.md` — monthly THI maps for MG
- `pages/concepts/ndvi-vegetation-indices.md` — NDVI, SVI formulas and data sources
- `pages/concepts/spi-spei-drought-indices.md` — SPI, SPEI methodology and comparison
- `pages/concepts/precipitation-dairy-production.md` — precipitation-production evidence synthesis
- `pages/entities/cileite.md` — CILeite/EMBRAPA dairy data platform

Pages updated (5):
- `pages/concepts/thermal-stress-dairy.md` — added genetic perspective (Boonkum), precipitation interaction (Dias-Souza)
- `pages/concepts/thi-temperature-humidity-index.md` — added NOAA formula, THI=76 threshold, spatial mapping section
- `pages/entities/embrapa.md` — added Monitoramento por Satélite, CILeite, research continuity note (R. Andrade)
- `pages/entities/inmet.md` — added MG dairy city usage
- `pages/entities/ibge-ppm.md` — added CILeite cross-reference
