---
title: "IDW — Inverse Distance Weighting Interpolation"
type: concept
created: 2026-04-15
updated: 2026-04-15
sources: ["ART+050_BJAER_JAN_2023.pdf"]
tags: [methodology, spatial-analysis]
---

# IDW — Inverse Distance Weighting Interpolation

A deterministic spatial interpolation method that estimates values at unsampled locations as a weighted average of nearby known points, where the weight is inversely proportional to distance raised to a power.

## Application in THI Mapping

[[andrade-2023-thi-maps-southeast-brazil|Andrade et al. (2023)]] used IDW with **power = 4** (IDW⁴) to interpolate THI values from INMET automatic weather stations across southeastern Brazil, producing continuous monthly raster maps.

Higher power values (e.g., 4 vs the common default of 2) give more weight to the nearest stations, producing sharper local estimates but potentially missing broader trends.

## Relevance to zarc-app

IDW is a candidate method for generating continuous climate risk surfaces from [[inmet]] point station data. Alternatives to consider: kriging (accounts for spatial autocorrelation), thin-plate splines, or machine learning approaches.

## See Also

- [[thi-temperature-humidity-index]]
- [[inmet]]
- [[andrade-2023-thi-maps-southeast-brazil]]
