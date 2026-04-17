---
title: "Silva et al. (2025) — Drought Indices and Vegetation Response in Paracatu River Basin"
type: source
created: 2026-04-17
updated: 2026-04-17
sources: ["Resumo_Expandido_Pamella_Silva_Atualizado_14_08_25.pdf"]
tags: [water-deficit, remote-sensing, cerrado, EMBRAPA, spatial-analysis, methodology, Brazil]
---

# Silva et al. (2025) — Drought Indices and Vegetation Response in Paracatu River Basin

## Bibliographic Metadata

| Field | Value |
|---|---|
| **Title (PT)** | Avaliação da Relação entre Índices Climáticos para o Monitoramento da Seca na Bacia do Rio Paracatu |
| **Title (EN)** | Assessment of the Relationship between Climate Indices for Drought Monitoring in the Paracatu River Basin |
| **Authors** | Pâmella Ferreira da Silva, Ricardo Guimarães Andrade, Celso Bandeira de Melo Ribeiro, Marcos Cicarini Hott |
| **Type** | Expanded abstract (Resumo Expandido) |
| **Date** | 2025 (updated 2025-08-14) |
| **Affiliation** | PIBIC/CNPq fellow at Embrapa Gado de Leite, Juiz de Fora, MG; UFJF |
| **Keywords** | drought, SPI, SPEI, NDVI, Cerrado, Paracatu River Basin |

**Note**: Ricardo G. Andrade and Marcos C. Hott are co-authors of [[andrade-2023-thi-maps-southeast-brazil]], indicating continuity of the EMBRAPA Gado de Leite research line into drought/water deficit monitoring.

## Summary

This study evaluates the relationship between **climate drought indices** (SPI, SPEI) and **vegetation response** (NDVI) in the [[paracatu-river-basin|Paracatu River Basin]], a key agricultural and livestock region in the Cerrado biome of Minas Gerais.

### Study Area

The **Bacia do Rio Paracatu** — located in the Cerrado, important for production of grains, coffee, milk, and beef. Faces growing water-use conflicts that intensify during prolonged droughts.

### Data Sources

| Dataset | Source | Resolution | Period |
|---|---|---|---|
| Precipitation | CHIRPS (Climate Hazards Group InfraRed Precipitation with Station data) | 0.05° (~5 km) | 2003–2023 |
| Evapotranspiration (ETp) | TerraClimate | 0.0417° (~4 km) | 2003–2023 |
| NDVI | MODIS (1 km) + GIMMS NDVI3g (~8 km) | see column | 2003–2023 |

### Indices Computed

- **SPI** (Standardized Precipitation Index) — based on precipitation only, following McKee et al. (1993)
- **SPEI** (Standardized Precipitation Evapotranspiration Index) — incorporates evapotranspiration, following Vicente-Serrano et al. (2010)
- Both computed at **3, 6, 9, and 12-month scales**
- **[[ndvi-vegetation-indices|NDVI]]** used as the vegetation response variable

### Methodology

- Cross-correlation with **lag test** to determine the temporal offset between drought events and vegetation response
- Processing: **Google Earth Engine** + **RStudio**
- Study area boundary: ANA (Agência Nacional de Águas) geospatial database (2025)
- Statistical significance at p < 0.05

### Key Results

| NDVI Scale | Index | Time Scale (months) | Optimal Lag (months) | Correlation (r) |
|---|---|---|---|---|
| NDVI3 | SPI | 3 | −4 | **−0.884** |
| NDVI3 | SPEI | 3 | −1 | 0.442 |
| NDVI6 | SPI | 6 | 2 | **0.894** |
| NDVI6 | SPEI | 6 | −5 | 0.329 |
| NDVI9 | SPI | 9 | 2 | 0.696 |
| NDVI9 | SPEI | 9 | −2 | −0.226 |
| NDVI12 | SPI | 12 | 3 | 0.15 |
| NDVI12 | SPEI | 12 | 7 | −0.206 |

**Main finding**: The **6-month SPI** showed the strongest positive correlation with NDVI (**r = 0.89, lag = 2 months**), making it the most suitable index for drought monitoring in this basin.

### Interpretation

- At 3-month scale: SPI shows strong **negative** correlation (r = −0.88, lag = −4), meaning short-term water deficit impacts vegetation rapidly
- SPI consistently outperforms SPEI for vegetation correlation at intermediate scales
- SPEI's inclusion of evapotranspiration introduces additional variability that weakens its correlation with vegetation in this context
- At 12-month scale: correlations are weak for both indices, suggesting annual-scale responses are influenced by other factors (land management, phenological conditions)

## Relevance to ZARC Research

- **Water deficit as a climate risk variable**: complements the THI-based thermal stress approach by adding a drought/precipitation dimension — consistent with [[dias-souza-2026-dairy-climate-minas-gerais|Dias-Souza et al. (2026)]]'s finding that precipitation is the dominant climatic driver of dairy production
- **SPI as a candidate index** for zarc-app: simpler to compute than SPEI (needs only precipitation), and the 6-month scale captures the most relevant vegetation impacts
- **Paracatu River Basin** is within the Cerrado core of MG, overlapping with dairy production zones
- **CHIRPS + TerraClimate** as gridded data alternatives to INMET station data for broader spatial coverage
- **Google Earth Engine** as a processing platform is relevant for scalable spatial analysis in the zarc-app ecosystem

## See Also

- [[spi-spei-drought-indices]]
- [[ndvi-vegetation-indices]]
- [[precipitation-dairy-production]]
- [[dias-souza-2026-dairy-climate-minas-gerais]]
- [[andrade-2023-thi-maps-southeast-brazil]]
- [[embrapa]]
- [[inmet]]
