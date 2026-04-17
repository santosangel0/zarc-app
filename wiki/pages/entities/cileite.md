---
title: "CILeite — Centro de Inteligência do Leite"
type: entity
created: 2026-04-17
updated: 2026-04-17
sources: ["Dairy farming and climate parameters.pdf"]
tags: [EMBRAPA, dairy, dataset, milk-production, Brazil]
---

# CILeite — Centro de Inteligência do Leite

The **Milk Intelligence Center** (Centro de Inteligência do Leite) is a platform maintained by [[embrapa|EMBRAPA Gado de Leite]] that provides cartographic and statistical data on dairy production across Brazilian municipalities.

## Data Available

- Milk production (thousand liters/year) per municipality
- Production density (L/km²)
- Cow density (animals/km²)
- Total milked cows (animals/year)
- Animal productivity (liters/animal/year)

## Usage

[[dias-souza-2026-dairy-climate-minas-gerais|Dias-Souza et al. (2026)]] used CILeite data for 2022 to identify and characterize high-productivity municipalities in Minas Gerais. The platform's cartographic data were integrated into Google Earth Engine for spatial analysis.

CILeite defines **high-productivity municipalities** as those exceeding **80,000 liters/year** — using this threshold, 12 out of 853 MG municipalities qualified (1.4%).

## Relation to Other Data Sources

- CILeite production data complements [[ibge-ppm|IBGE PPM]] — the PPM provides the official census-level production statistics, while CILeite adds EMBRAPA-curated spatial layers and derived metrics
- Climate data for CILeite municipalities comes from [[inmet|INMET]]

## See Also

- [[embrapa]]
- [[ibge-ppm]]
- [[dias-souza-2026-dairy-climate-minas-gerais]]
