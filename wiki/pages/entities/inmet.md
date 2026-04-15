---
title: "INMET"
type: entity
created: 2026-04-15
updated: 2026-04-15
sources: ["ART+050_BJAER_JAN_2023.pdf"]
tags: [INMET, dataset, Brazil, climate-risk]
---

# INMET — Instituto Nacional de Meteorologia

Brazil's national meteorological institute. Operates the country's network of automatic and conventional weather stations, providing historical and real-time climate data.

## Data Used in This Research

- **Automatic weather stations** across southeastern Brazil.
- **Variables**: air temperature (Tbs), relative humidity (UR) — the two inputs to the [[thi-temperature-humidity-index|THI]] formula.
- **Period**: January 2007 – December 2021 (in [[andrade-2023-thi-maps-southeast-brazil|Andrade et al. 2023]]).
- Data requires **consistency analysis** and correction of observational record gaps before use.

## Role in zarc-app

The zarc-app ingests INMET historical data via a parquet-based pipeline. Station data (`estacoes.parquet`) and historical records (`inmet_historico.parquet`) are stored in `data/`. See [[inmet-pipeline]] for technical details.

## See Also

- [[embrapa]]
- [[ibge-ppm]]
- [[thi-temperature-humidity-index]]
- [[andrade-2023-thi-maps-southeast-brazil]]
