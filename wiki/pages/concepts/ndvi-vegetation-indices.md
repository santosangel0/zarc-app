---
title: "NDVI and Vegetation Indices"
type: concept
created: 2026-04-17
updated: 2026-04-17
sources: ["Resumo_Expandido_Pamella_Silva_Atualizado_14_08_25.pdf", "AVALIAÇÃO DO ÍNDICE DE VEGETAÇÃO PADRONIZADO.pdf"]
tags: [remote-sensing, methodology, spatial-analysis, water-deficit, pasture]
---

# NDVI and Vegetation Indices

## NDVI — Normalized Difference Vegetation Index

The **NDVI** (Índice de Vegetação por Diferença Normalizada) is the most widely used index for monitoring vegetation vigor from satellite imagery (Rouse et al. 1974).

### Formula

```
NDVI = (NIR − RED) / (NIR + RED)
```

Where NIR = near-infrared reflectance, RED = red band reflectance.

- Range: **−1 to +1**
- Negative values → water bodies, clouds
- Near zero → bare soil, exposed ground
- Higher values → denser, healthier vegetation
- Minimizes topographic effects due to normalization

### Common Data Sources

| Sensor/Product | Resolution | Provider |
|---|---|---|
| MODIS (MOD-13) | 1 km, 16-day | NASA |
| GIMMS NDVI3g | ~8 km, biweekly | NASA/NOAA |
| SPOT-Vegetation | 1 km, 10-day (decadal) | VITO (Belgium) |
| Sentinel-2 | 10 m, 5-day | ESA |
| Landsat | 30 m, 16-day | USGS |

## SVI — Standard Vegetation Index

The **SVI** (Índice de Vegetação Padronizado, IVP) standardizes NDVI anomalies relative to the historical baseline for a given pixel and time period (Park et al. 2008). Used for drought monitoring.

### Formula

```
SVI = (NDVI_current − NDVI_mean) / σ
```

Negative SVI → vegetation below historical normal (drought indicator). Positive SVI → above normal. See [[leivas-2014-svi-drought-soybean-south-brazil]] for classification thresholds and application.

## Application in This Research

- [[silva-2025-drought-indices-paracatu|Silva et al. (2025)]]: NDVI from MODIS and GIMMS as the response variable for drought index correlation in the Paracatu River Basin. Best correlation: 6-month SPI with NDVI (r = 0.89).
- [[leivas-2014-svi-drought-soybean-south-brazil|Leivas et al. (2014)]]: SVI from SPOT-Vegetation NDVI (1998–2012) for drought monitoring in soybean areas of Southern Brazil. Identified major drought years (2004/05, 2008/09, 2011/12).
- Both studies confirm that NDVI responds to precipitation anomalies with a **temporal lag**, making it useful for monitoring but not forecasting.

## Relevance to Dairy/Pasture

NDVI can serve as a proxy for **pasture quality and forage availability** — key determinants of milk production in extensive and semi-intensive dairy systems. Declining NDVI in pasture areas signals reduced feed availability, potentially preceding drops in milk output.

## See Also

- [[spi-spei-drought-indices]]
- [[precipitation-dairy-production]]
- [[silva-2025-drought-indices-paracatu]]
- [[leivas-2014-svi-drought-soybean-south-brazil]]
