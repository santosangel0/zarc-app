---
title: "Dias-Souza et al. (2026) — Dairy Farming and Climate Parameters in Minas Gerais"
type: source
created: 2026-04-17
updated: 2026-04-17
sources: ["Dairy farming and climate parameters.pdf"]
tags: [dairy, milk-production, climate-risk, Minas Gerais, precipitation, EMBRAPA, INMET, IBGE, spatial-analysis, Brazil]
---

# Dias-Souza et al. (2026) — Dairy Farming and Climate Parameters in Minas Gerais

## Bibliographic Metadata

| Field | Value |
|---|---|
| **Title** | Dairy farming and climate parameters: an analysis of high productivity milk-producing cities in Minas Gerais, the leading dairy state in Brazil |
| **Title (PT)** | Pecuária leiteira e parâmetros climáticos: análise de municípios de alta produtividade em Minas Gerais, o principal estado em produção leiteira do Brasil |
| **Authors** | Marcus Vinícius Dias-Souza, Gustavo Augusto Bitancourt Oliveira, Amanda de Barros Martins |
| **Journal** | Brazilian Journal of Veterinary Medicine |
| **Volume** | 48 |
| **Article** | e008525 |
| **Date** | 2026 (received 2025-09-04, accepted 2025-10-28) |
| **DOI** | [10.29374/2527-2179.bjvm008525](https://doi.org/10.29374/2527-2179.bjvm008525) |
| **Affiliation** | Centro Universitário Católica do Leste de Minas Gerais (UBEC), Coronel Fabriciano, MG |
| **Keywords** | dairy cattle, climate change, milk production, dairy farming |

## Summary

This study evaluates milk production in the state of **Minas Gerais** — Brazil's leading dairy state — by analyzing the relationship between official productivity data and climatic parameters (temperature and precipitation) for high-productivity municipalities.

### Data Sources

- **Milk production**: [[cileite|CILeite/EMBRAPA]] platform — year 2022, selected as the most recent post-COVID year. High-productivity threshold: **>80,000 L/year**.
- **Climate**: [[inmet|INMET]] database — daily precipitation and dry-bulb air temperature.
- **Geographic**: [[ibge-ppm|IBGE]] boundaries and production volumes.
- **Processing**: CILeite cartographic data integrated into Google Earth Engine using JavaScript scripts (developed with ChatGPT AI). Cross-checked with official state government maps.

### Key Findings

1. **12 high-productivity cities** identified (out of 853 in MG, 1.4%): Pompéu, Passos, Prata, Unaí, João Pinheiro, Coromandel, Patrocínio, Patos de Minas, Lagoa Formosa, Carmo do Paranaíba, Rio Paranaíba, and Tiros. All from the Alto Paranaíba region except Pompéu (Central) and Passos (Southern).

2. **Precipitation is the dominant climatic driver** of milk production:
   - Quadratic polynomial regression: **R² = 0.8993, p = 0.0076**
   - Each 1 mm increase in precipitation → estimated 73.08 liters increase in production
   - Each 1°C increase in average temperature → estimated decrease of **>10,000 liters/year** (b₂ = −10,202.76), but this was **not statistically significant** (R² = 0.1995, p = 0.7174)

3. **Pearson correlation**: significant for precipitation × production (R² = 0.6490, p = 0.0530), not for temperature (R² = 0.0626, p = 0.6324).

4. **High-productivity areas** maintained moderate temperatures (21–23°C) and lower animal densities (animals/km²).

5. **Pompéu** stood out: >40,000 milked cows, highest precipitation (1,250.8 mm/year), highest herd size.

6. **Patos de Minas** had the highest total annual precipitation (1,940.6 mm) and the highest production index among the six analyzed cities.

### Statistical Methods

- Shapiro-Wilk (normality), Bartlett's (homoscedasticity), Yeo-Johnson transformation
- ANOVA + post-hoc Tukey for temperature/precipitation differences
- Pearson correlation, multiple linear & quadratic polynomial regression
- PCA for climatic data dimensionality reduction and intercity similarity
- Tools: Biostat 5.0, PAST 5.2; significance at p < 0.05

### Climatic Profiles of Analyzed Cities

| City | Avg Temp (°C) | Precip (mm/year) | Rainy season | Notes |
|---|---|---|---|---|
| Passos | 21.0 | 330.58 | Dec–Feb | Longest dry period (May–Aug) |
| Unaí | 22.1 | 1,211.6 | Jan peak | Rain concentrated in Q1 |
| Pompéu | 23.5 | 1,250.8 | Jan peak | Drought Jun–Aug; highest temp |
| João Pinheiro | 21.8 | — | Jan peak | Shortest rainy period (25 rain days/year) |
| Patrocínio | 22.12 | 1,638.4 | Feb peak | Longest rainy period (85 rain days) |
| Patos de Minas | 21.6 | 1,940.6 | Jan peak | Highest total precipitation |

### Breed Context

- Intensive farming system in these cities, not extensive pasture
- **Girolando** (Gir × Holstein crossbreed) is most common, followed by pure Holstein
- Thermal comfort zones: Holstein 21°C, Girolando 18°C — the studied cities (21–23°C) require fewer adaptations
- Government program "Mais Genética" provides selected semen for genetic improvement

## Relevance to ZARC Research

- **Complements THI-based analysis** ([[andrade-2023-thi-maps-southeast-brazil]]) with a production-centric perspective: rather than mapping thermal stress zones, this study asks which climatic variables actually predict productivity at the municipality level.
- **Precipitation > temperature** as a production driver is a key insight — suggests that water deficit / [[spi-spei-drought-indices|drought indices]] may be more predictive of dairy output than [[thi-temperature-humidity-index|THI]] alone in MG.
- **CILeite platform** is a new data source for the zarc-app ecosystem.
- Confirms the geographic concentration of high-productivity dairy in **Alto Paranaíba** and Central MG — regions that also appear as THI comfort zones in Andrade et al. (2023).

## See Also

- [[andrade-2023-thi-maps-southeast-brazil]]
- [[cileite]]
- [[thermal-stress-dairy]]
- [[thi-temperature-humidity-index]]
- [[precipitation-dairy-production]]
- [[embrapa]]
- [[inmet]]
- [[ibge-ppm]]
