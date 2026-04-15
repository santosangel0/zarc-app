---
title: "IBGE PPM — Pesquisa Pecuária Municipal"
type: entity
created: 2026-04-15
updated: 2026-04-15
sources: ["ART+050_BJAER_JAN_2023.pdf"]
tags: [IBGE, dataset, dairy, milk-production, Brazil]
---

# IBGE PPM — Pesquisa Pecuária Municipal

The **Municipal Livestock Survey** (Pesquisa Pecuária Municipal) is an annual IBGE survey covering livestock production at the municipality level across Brazil. It is the official source for milk production statistics.

## Key Data Points (2021)

- National milk production: **35.3 billion liters**.
- Southeast region: **34%** of national total.
- Southeast average productivity: **2,537 liters/cow/year** — 1,163 liters below the South region average.

## Access

Available via [[sidra|SIDRA]] (Sistema IBGE de Recuperação Automática): https://sidra.ibge.gov.br/home/cnt/brasil

## Role in zarc-app

The zarc-app fetches PPM milk production data through the SIDRA API (`app/logic/ibge.R`) to power the Leaflet choropleth visualization at the municipality level.

## Relevance

PPM data provides the **production side** of the climate risk equation: which municipalities produce how much milk, enabling correlation with climate stress indices like [[thi-temperature-humidity-index|THI]]. [[andrade-2023-thi-maps-southeast-brazil|Andrade et al. (2023)]] used PPM productivity data to show r = 0.66 correlation between summer THI and mesoregion milk yield.

## See Also

- [[inmet]]
- [[embrapa]]
- [[andrade-2023-thi-maps-southeast-brazil]]
