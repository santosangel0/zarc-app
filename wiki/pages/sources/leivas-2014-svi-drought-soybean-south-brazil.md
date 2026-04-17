---
title: "Leivas et al. (2014) — Standard Vegetation Index for Drought Monitoring in Southern Brazil"
type: source
created: 2026-04-17
updated: 2026-04-17
sources: ["AVALIAÇÃO DO ÍNDICE DE VEGETAÇÃO PADRONIZADO.pdf"]
tags: [remote-sensing, water-deficit, spatial-analysis, EMBRAPA, methodology, Brazil]
---

# Leivas et al. (2014) — Standard Vegetation Index for Drought Monitoring in Southern Brazil

## Bibliographic Metadata

| Field | Value |
|---|---|
| **Title (PT)** | Avaliação do Índice de Vegetação Padronizado no Monitoramento Indicativo de Estiagens em Períodos Críticos da Soja no Sul do Brasil |
| **Title (EN)** | Standard Vegetation Index Assessment in the Indicative Monitoring of Droughts for Soybean Crops in the Southern Region of Brazil |
| **Authors** | Janice Freitas Leivas, Ricardo Guimarães Andrade, Daniel de Castro Victoria, Fabio Enrique Torresan, Luiz Eduardo Vicente, Antonio Heriberto de Castro Teixeira, Edson Luis Bolfe, Thiago Renato de Barros |
| **Journal** | Revista Brasileira de Cartografia |
| **Volume/Issue** | 66/5, pp. 1145–1155 |
| **ISSN** | 1808-0936 |
| **Date** | 2014 (received 2014-05-14, accepted 2014-06-19) |
| **Affiliation** | EMBRAPA Monitoramento por Satélite, Campinas, SP |
| **Keywords** | Standard Vegetation Index (SVI/IVP), SPOT-Vegetation, Soybean, Drought |

**Note**: Ricardo G. Andrade is also co-author of [[andrade-2023-thi-maps-southeast-brazil]] and [[silva-2025-drought-indices-paracatu]], reflecting his long trajectory in remote sensing and climate monitoring at EMBRAPA.

## Summary

This study evaluates the **Standard Vegetation Index** (SVI; Portuguese: **Índice de Vegetação Padronizado**, IVP) as a tool for indicative drought monitoring during critical growth periods of **soybean** crops in Southern Brazil (RS, SC, PR).

### Data Sources

- **SPOT-Vegetation** sensor: decadal (10-day) NDVI composites (product V2KRN_S-10_S-America), 1 km spatial resolution, 8-bit radiometric resolution, HDF→GeoTiff conversion, WGS84
- **Period**: 1998–2012 (129 decadal images processed)
- **TRMM** (Tropical Rainfall Measuring Mission): monthly precipitation estimates, product 3B43, 0.25° (~25 km) resolution — used for rainfall anomaly validation
- **Study area**: Municipalities in RS, SC, PR with >7,000 ha of soybean (PAM/IBGE 2009), covering 85% of soybean area in the South

### SVI Formula

```
SVI_dec = (NDVI_dec − NDVI_mean_dec) / σ_dec
```

Where:
- `NDVI_dec` = vegetation index for the specific 10-day period
- `NDVI_mean_dec` = multi-year average NDVI for that same 10-day period
- `σ_dec` = standard deviation across years for that 10-day period

The SVI standardizes NDVI anomalies as **deviations from the historical mean**, enabling comparison across regions and time periods. Based on Park et al. (2008).

### SVI Classification

| SVI Range | Category | Map Color |
|---|---|---|
| ≤ −2.0 | Far below normal | Dark red |
| −2.0 to −1.5 | Below normal | Red |
| −1.5 to −1.0 | Slightly below normal | Orange |
| −1.0 to 1.0 | Normal | Yellow |
| 1.0 to 1.5 | Slightly above normal | Light green |
| 1.5 to 2.0 | Above normal | Green |
| ≥ 2.0 | Far above normal | Dark green |

### Analysis Period

Critical soybean phase: **1st ten-day period of December to 3rd ten-day period of February** (flowering and grain filling), for agricultural years 2004/05 through 2011/12.

### Key Findings

1. **Major drought years identified**: 2004/05, 2008/09, and 2011/12 — all showed extensive areas with negative SVI anomalies (below-normal vegetation vigor), coinciding with significant soybean production losses.

2. **2011/12 drought**: most severe in the analyzed period. SVI far below normal across the entire study area. La Niña reduced precipitation, combined with high temperatures (INMET data). Soybean production dropped by 8.95 million tonnes (from 75.32 to 66.37 million). RS lost 43.8%, PR lost 29.4%, SC lost 25.9%.

3. **Normal/good years** (2005/06, 2006/07, 2007/08, 2009/10, 2010/11): SVI predominantly normal to above normal, corresponding to adequate or above-average rainfall.

4. **Precipitation anomaly validation**: The Standardized Precipitation Index (IPP) from TRMM data confirmed the temporal and spatial patterns, though the correlation between SVI and IPP was weak numerically — attributed to the large resolution difference (1 km vs 25 km). Visual analysis was recommended over statistical correlation.

5. **Vegetation lag**: NDVI response to precipitation shows a temporal lag, consistent with other studies (Gonçalves 2008; Campos et al. 2009).

## Relevance to ZARC Research

- **SVI methodology** is directly transferable to dairy pasture monitoring — instead of soybean, apply to pasture NDVI to detect water-deficit stress periods that reduce forage availability and hence milk production
- The **decadal (10-day) temporal resolution** provides near-real-time monitoring capability relevant to operational decision-making
- Validates that **NDVI anomalies correspond to precipitation anomalies** with a lag — same principle underlying [[silva-2025-drought-indices-paracatu|Silva et al. (2025)]]'s SPI–NDVI correlation work
- **EMBRAPA Monitoramento por Satélite** (now EMBRAPA Territorial) provides institutional capacity for operationalizing this kind of monitoring
- The classification table (SVI ranges → anomaly categories) is a ready-made framework for risk categorization in zarc-app

## See Also

- [[ndvi-vegetation-indices]]
- [[spi-spei-drought-indices]]
- [[silva-2025-drought-indices-paracatu]]
- [[precipitation-dairy-production]]
- [[embrapa]]
