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
