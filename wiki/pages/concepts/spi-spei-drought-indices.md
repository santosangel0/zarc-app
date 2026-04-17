---
title: "SPI and SPEI — Drought Indices"
type: concept
created: 2026-04-17
updated: 2026-04-17
sources: ["Resumo_Expandido_Pamella_Silva_Atualizado_14_08_25.pdf", "AVALIAÇÃO DO ÍNDICE DE VEGETAÇÃO PADRONIZADO.pdf"]
tags: [water-deficit, methodology, climate-risk, cerrado]
---

# SPI and SPEI — Drought Indices

Standardized drought indices that quantify water deficit/surplus relative to historical baselines. Both are computed at multiple time scales (1, 3, 6, 9, 12 months), capturing different aspects of drought.

## SPI — Standardized Precipitation Index

Developed by McKee et al. (1993). Uses **precipitation only**.

- Fits a gamma distribution to the historical precipitation record, then transforms to a standard normal distribution
- Positive values = wetter than normal; negative values = drier than normal
- **Advantage**: requires only precipitation data, widely available
- **Limitation**: ignores evapotranspiration, so may underestimate drought severity in warming scenarios

### SPI Classification

| SPI Value | Category |
|---|---|
| ≥ 2.0 | Extremely wet |
| 1.5 to 1.99 | Very wet |
| 1.0 to 1.49 | Moderately wet |
| −0.99 to 0.99 | Near normal |
| −1.0 to −1.49 | Moderately dry |
| −1.5 to −1.99 | Severely dry |
| ≤ −2.0 | Extremely dry |

## SPEI — Standardized Precipitation Evapotranspiration Index

Developed by Vicente-Serrano et al. (2010). Uses **precipitation minus potential evapotranspiration (P − ETp)**.

- Same standardization approach as SPI, but on the water balance rather than precipitation alone
- **Advantage**: accounts for temperature-driven evaporative demand, making it more sensitive to climate warming
- **Limitation**: requires evapotranspiration data (or estimates), adding complexity; the additional variability from ETp can weaken correlations with vegetation in some contexts

## Comparison in Practice

[[silva-2025-drought-indices-paracatu|Silva et al. (2025)]] compared SPI and SPEI at multiple scales against [[ndvi-vegetation-indices|NDVI]] in the Paracatu River Basin (Cerrado):

| Scale | Best Index | Correlation with NDVI | Lag |
|---|---|---|---|
| 3-month | SPI | r = −0.88 | −4 months |
| **6-month** | **SPI** | **r = 0.89** | **2 months** |
| 9-month | SPI | r = 0.70 | 2 months |
| 12-month | SPI | r = 0.15 | 3 months |

**Key finding**: SPI consistently outperformed SPEI for vegetation correlation. The 6-month scale captured the strongest relationship with vegetation vigor, making it the recommended scale for agricultural/pastoral drought monitoring in the Cerrado.

## Data Sources for Computation

- **Precipitation**: CHIRPS (~5 km), TRMM (~25 km), INMET station data
- **Evapotranspiration**: TerraClimate (~4 km), MODIS ET products
- **Processing**: Google Earth Engine, RStudio

## Relevance to ZARC Research

SPI (6-month scale) is a strong candidate for a **water deficit risk layer** in the zarc-app, complementing the [[thi-temperature-humidity-index|THI]] thermal stress layer. Together, they capture the two main climate risk dimensions for dairy:
1. **Thermal stress** (THI) → direct impact on animal physiology
2. **Water deficit** (SPI) → indirect impact via pasture quality and forage availability

[[dias-souza-2026-dairy-climate-minas-gerais|Dias-Souza et al. (2026)]] found that precipitation explains 83% of milk production variation in high-productivity MG cities — further supporting the importance of a drought index in dairy risk zoning.

## See Also

- [[ndvi-vegetation-indices]]
- [[precipitation-dairy-production]]
- [[thi-temperature-humidity-index]]
- [[silva-2025-drought-indices-paracatu]]
- [[leivas-2014-svi-drought-soybean-south-brazil]]
