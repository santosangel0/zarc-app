---
title: "Estimativa e Espacialização do THI para Minas Gerais"
type: source
created: 2026-04-17
updated: 2026-04-17
sources: ["Estimativa-espacializacao.pdf"]
tags: [thermal-stress, dairy, spatial-analysis, Minas Gerais, methodology]
---

# Estimativa e Espacialização do THI para Minas Gerais

## Bibliographic Metadata

| Field | Value |
|---|---|
| **Title (inferred)** | Estimativa e espacialização do Índice de Temperatura e Umidade (ITU) para Minas Gerais |
| **Authors** | Unknown (text extraction limited) |
| **Source file** | `Estimativa-espacializacao.pdf` |

**Note**: PDF text extraction was severely limited for this document. The summary below is based on visible maps, fragments, and visual content analysis.

## Summary

This source provides **monthly THI (ITU) spatialization maps for the state of Minas Gerais**, showing the spatial distribution of thermal stress conditions throughout the year.

### Visible Content

The document contains two sets of monthly maps:

1. **Set 1** (scale 57–75): Appears to show monthly mean THI for a specific period or metric, covering MG. Higher values (orange-red) concentrated in northern MG, lower values (green-blue) in southern highland areas.

2. **Set 2** (scale 47–79): Monthly maps from **Janeiro to Dezembro** showing broader THI variation. Clear seasonal pattern:
   - **Summer months (Dec–Mar)**: Most of MG in the 71–79 range (orange-red), indicating widespread thermal stress risk
   - **Winter months (Jun–Aug)**: Southern MG drops to 47–63 range (green-yellow), indicating comfort conditions
   - **Transition months (Apr–May, Sep–Nov)**: Intermediate values with geographic gradients

### Text Fragments Extracted

- References "ocorrência de 'ilhas' nos mapas" (occurrence of "islands" in the maps) — likely discussing spatial artifacts from interpolation
- References "prejudicada quando o ITU for ≥ 72 (Kemer et al., 2020)" — confirming use of the **THI ≥ 72 threshold** for dairy production impact, consistent with [[thi-temperature-humidity-index]]
- Uses the same threshold framework as [[andrade-2023-thi-maps-southeast-brazil]]

### Spatial Patterns

The maps reveal consistent geographic patterns for MG:
- **Northern MG / Vale do Jequitinhonha**: highest THI year-round, most vulnerable to thermal stress
- **Triângulo Mineiro**: elevated summer THI but moderate winter values
- **Sul de Minas / Alto Paranaíba**: lowest THI values, most comfortable conditions — aligns with the location of high-productivity dairy cities identified by [[dias-souza-2026-dairy-climate-minas-gerais|Dias-Souza et al. (2026)]]
- **Highland areas** (Serra da Mantiqueira, Serra do Espinhaço): localized cool spots visible as "islands" of lower THI

## Relevance to ZARC Research

- Provides a **MG-specific THI spatial layer** that complements the broader SE Brazil maps from [[andrade-2023-thi-maps-southeast-brazil|Andrade et al. (2023)]]
- The monthly resolution enables identification of **seasonal windows** for thermal stress risk management
- Geographic patterns confirm that the most productive dairy regions in MG coincide with lower THI zones

## See Also

- [[thi-temperature-humidity-index]]
- [[thermal-stress-dairy]]
- [[andrade-2023-thi-maps-southeast-brazil]]
- [[dias-souza-2026-dairy-climate-minas-gerais]]
- [[idw-interpolation]]
