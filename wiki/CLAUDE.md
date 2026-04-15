# ZARC Wiki — Schema & Operating Manual

> Agricultural Zoning for Climate Risk — Dairy Farming Research Wiki
> Maintained by Claude Code. Read by the researcher. Fed by curated sources.

---

## Purpose

This wiki is a persistent, compounding knowledge base for research on **agricultural zoning, climate risk, and dairy farming in Brazil**. It sits alongside the `zarc-app` codebase — a Rhino/Shiny application for geographic intelligence on milk production.

The wiki captures knowledge that lives *outside* the code: literature reviews, dataset documentation, policy context, methodological notes, institutional knowledge about INMET/IBGE/EMBRAPA/MAPA, and the evolving research synthesis.

---

## Directory Structure

```
wiki/
├── CLAUDE.md          # This file — schema and operating rules
├── index.md           # Content-oriented catalog of all wiki pages
├── log.md             # Chronological record of all operations
├── raw/               # Immutable source documents (articles, PDFs, clippings)
│   └── assets/        # Downloaded images referenced by sources
└── pages/             # LLM-generated wiki pages (the wiki itself)
    ├── sources/       # One summary page per ingested source
    ├── entities/      # Institutions, datasets, people, places, programs
    ├── concepts/      # Topics, methods, theories, policies
    └── analyses/      # Query results, comparisons, syntheses worth keeping
```

### Rules

- **`raw/`** is immutable. The LLM reads from it, never modifies it.
- **`pages/`** is LLM-owned. The LLM creates, updates, and maintains all files here.
- **`index.md`** and **`log.md`** live at the wiki root and are updated on every operation.
- The researcher curates `raw/`, asks questions, and directs analysis. The LLM does everything else.

---

## Page Format

Every page in `pages/` uses this template:

```markdown
---
title: "Page Title"
type: source | entity | concept | analysis
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources: [list of source filenames that inform this page]
tags: [domain-relevant tags]
---

# Page Title

Content here. Use [[wiki-links]] for cross-references to other pages
(Obsidian-style double-bracket links, filename without extension).

## See Also

- [[related-page-1]]
- [[related-page-2]]
```

### Naming Conventions

- Filenames: `kebab-case.md` (e.g., `inmet-weather-stations.md`, `zarc-policy.md`)
- Source pages: named after the source (e.g., `assad-2004-climate-risk-zoning.md`)
- Entity pages: named after the entity (e.g., `embrapa.md`, `ibge-ppm.md`)
- Concept pages: named after the concept (e.g., `agroclimatic-zoning.md`, `thermal-stress-dairy.md`)

### Tags Vocabulary

Use consistent tags. Preferred tags (expand as needed):

`climate-risk` · `zoning` · `dairy` · `milk-production` · `pasture` · `thermal-stress` · `water-deficit` · `ZARC` · `INMET` · `IBGE` · `EMBRAPA` · `MAPA` · `remote-sensing` · `spatial-analysis` · `policy` · `methodology` · `dataset` · `Brazil` · `cerrado` · `atlantic-forest` · `semi-arid`

---

## Operations

### 1. Ingest

Triggered when the researcher adds a source to `raw/` and asks the LLM to process it.

**Workflow:**

1. Read the source document in full.
2. Discuss key takeaways with the researcher — what's interesting, what to emphasize.
3. Create a source summary page in `pages/sources/`.
4. Update or create relevant entity pages in `pages/entities/`.
5. Update or create relevant concept pages in `pages/concepts/`.
6. Add cross-references (`[[wiki-links]]`) across all touched pages.
7. Update `index.md` with new/modified pages.
8. Append an entry to `log.md`.

**A single ingest should touch multiple pages.** The value is in integration, not just summarization. When a new source mentions EMBRAPA, update the EMBRAPA entity page. When it discusses thermal stress, update or create the thermal stress concept page. Connect the dots.

### 2. Query

Triggered when the researcher asks a question.

**Workflow:**

1. Read `index.md` to identify relevant pages.
2. Read the relevant pages.
3. Synthesize an answer with `[[wiki-links]]` citations to wiki pages.
4. If the answer is substantial and reusable, offer to file it as an analysis page in `pages/analyses/`.
5. If filing, update `index.md` and append to `log.md`.

### 3. Lint

Triggered when the researcher asks for a health check, or proactively suggested after significant growth.

**Checks:**

- [ ] Contradictions between pages
- [ ] Stale claims superseded by newer sources
- [ ] Orphan pages (no inbound links)
- [ ] Important concepts mentioned but lacking their own page
- [ ] Missing cross-references
- [ ] Data/knowledge gaps that suggest new sources to seek
- [ ] Index accuracy — every page listed, summaries current

Report findings and fix issues with researcher approval.

---

## Domain Context

This wiki supports research at the intersection of:

- **ZARC (Zoneamento Agrícola de Risco Climático)** — Brazil's official agricultural climate risk zoning system, managed by MAPA with technical support from EMBRAPA.
- **Dairy farming** — specifically milk production vulnerability to climate variability across Brazilian municipalities.
- **Climate data** — INMET historical weather station data, remote sensing, agroclimatic indices.
- **Geospatial analysis** — municipal-level spatial data from IBGE, choropleth mapping, spatial joins.
- **The zarc-app itself** — an R Shiny application that visualizes this data. The wiki documents the *knowledge*; the app operationalizes it.

### Key Institutions

| Abbreviation | Full Name | Role |
|---|---|---|
| MAPA | Ministério da Agricultura, Pecuária e Abastecimento | Publishes ZARC portarias |
| EMBRAPA | Empresa Brasileira de Pesquisa Agropecuária | Technical research behind ZARC |
| INMET | Instituto Nacional de Meteorologia | Weather station network & historical data |
| IBGE | Instituto Brasileiro de Geografia e Estatística | Census, geographic boundaries, PPM livestock survey |
| SIDRA | Sistema IBGE de Recuperação Automática | API for IBGE statistical tables |

---

## Conventions

- All dates in ISO 8601 (`YYYY-MM-DD`).
- Portuguese terms kept when they are the standard (e.g., "mesoregião", "município", "portaria"). Provide English gloss on first use in a page.
- Currency in BRL unless otherwise noted.
- Geographic coordinates in EPSG:4326 (WGS84) unless otherwise noted.
- Source citations include author, year, and title. Full bibliographic details go on the source page.
- When a wiki page makes a factual claim, it should link to the source page(s) that support it.

---

## Session Protocol

At the start of every conversation:

1. Read `CLAUDE.md` (this file) to load the schema.
2. Read `index.md` to know what exists.
3. Read the tail of `log.md` to know what happened recently.
4. Ask the researcher: **"What are we working on today — ingest, query, or lint?"**

This ensures continuity across sessions.
