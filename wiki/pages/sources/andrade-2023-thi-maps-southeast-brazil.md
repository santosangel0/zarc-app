---
title: "Andrade et al. (2023) — Monthly THI Maps for Southeastern Brazil"
type: source
created: 2026-04-15
updated: 2026-04-15
sources: ["ART+050_BJAER_JAN_2023.pdf"]
tags: [thermal-stress, dairy, INMET, EMBRAPA, IBGE, spatial-analysis, methodology, Brazil]
---

# Andrade et al. (2023) — Monthly THI Maps for Southeastern Brazil

## Bibliographic Metadata

| Field | Value |
|---|---|
| **Title** | Análise e disponibilização de mapas mensais do Índice de Temperatura e Umidade (ITU) para o Sudeste do Brasil |
| **Title (EN)** | Analysis and availability of monthly maps of the Temperature and Humidity Index (THI) for Southeastern Brazil |
| **Authors** | Ricardo Guimarães Andrade, Lucas Cantarino Soares Garcia, Marcos Cicarini Hott, Walter Coelho Pereira de Magalhães Junior, Maria Gabriela Campolina Diniz Peixoto, Maria de Fatima Ávila Pires, Alexandro Gomes Facco |
| **Journal** | Brazilian Journal of Animal and Environmental Research (BJAER) |
| **ISSN** | 2595-573X |
| **Volume/Issue** | v.6, n.1 |
| **Pages** | 560–568 |
| **Date** | Jan./Mar. 2023 |
| **DOI** | [10.34188/bjaerv6n1-050](https://doi.org/10.34188/bjaerv6n1-050) |
| **Received** | 2022-12-20 |
| **Accepted** | 2023-01-02 |
| **Affiliation** | EMBRAPA Gado de Leite (Juiz de Fora, MG); UFJF; UFES Campus São Mateus |
| **Keywords** | Animal welfare, heat stress, THI, dairy cattle |

## Summary

The study generates and publishes **monthly THI (Temperature and Humidity Index) maps** for southeastern Brazil using 15 years of INMET automatic weather station data (2007–2021). The THI is computed per station using the Buffington (1977) equation, then spatially interpolated via **inverse distance weighting (4th power)** to produce continuous raster maps.

### THI Formula

```
THI = 0.8 × Tbs + UR × (Tbs − 14.3) / 100 + 46.3
```

Where `Tbs` = dry bulb temperature (°C), `UR` = relative humidity (%).

### THI Classification (Du Preez et al. 1990)

| THI Range | Condition |
|---|---|
| ≤ 70 | Normal thermal comfort |
| 70–72 | Alert |
| 72–78 | Alert with milk production restrictions |
| 78–82 | Danger |
| > 82 | Emergency |

## Key Findings

1. **Seasonal pattern**: THI ≤ 70 (comfort) predominates May–September. THI ≥ 72 (production risk) predominates December–March.

2. **Geographic risk zones**: Most of Espírito Santo, Rio de Janeiro, western São Paulo, Triângulo Mineiro, and NE/N Minas Gerais face elevated thermal stress in summer.

3. **Safe zones year-round (THI ≤ 72 all months)**: Alto Paranaíba, Noroeste de Minas, Sul/Sudoeste de Minas, Campo das Vertentes, Oeste de Minas, Central Mineira, Metropolitana de BH, Macro-metropolitana Paulista, Metropolitana de SP, Itapetininga.

4. **Mesoregion analysis**: 80% of SE mesoregions (30/37) had THI > 70 across all summer months. 43% (16/37) had mean THI ≥ 72 in all summer months.

5. **Productivity correlation**: Among the top 15 most productive mesoregions, R² = 0.44 (r = 0.66) between summer THI and milk yield (liters/head/year). Only 3 of the 15 most productive mesoregions had THI ≥ 72 in all summer months — and they ranked last among the 15.

6. **Breed-dependent response**: Zebu thermoneutral zone 10–32°C; Holstein 4–26°C. Selection for high milk yield can erode heat tolerance even in Zebu breeds (Santana Jr. et al. 2015).

## Relevance to ZARC Research

- **Same data infrastructure**: INMET automatic stations + IBGE PPM production data + mesoregion geographic units — directly parallels the [[inmet-pipeline]] and [[ibge-sidra-integration]] in zarc-app.
- **THI as a climate risk index**: provides a concrete, validated metric for the climate risk dimension of agricultural zoning for dairy.
- **Spatial interpolation method** (IDW⁴) is a candidate approach for generating continuous risk surfaces from point station data.
- **Maps published on EMBRAPA GeoInfo**: http://geoinfo.cnpgl.embrapa.br/maps/998

## Citations Referenced

| Citation | Topic |
|---|---|
| Buffington et al. (1977) | Original THI formula |
| Du Preez et al. (1990) | THI classification thresholds |
| Kemer et al. (2020) | THI comfort indices for dairy cattle in Santa Catarina |
| Santana et al. (2020) | Guzerá dual-purpose cattle performance under heat stress |
| Santana Jr. et al. (2015) | Selection for milk yield erodes heat tolerance in Zebu |
| Berman (2011) | Adaptations for dairy productivity in warm climates |
| Bernabucci et al. (2010) | Metabolic acclimation to heat stress in ruminants |
| McManus et al. (2011) | Multivariate heat tolerance in Brazilian cattle |
| Nardone et al. (2010) | Climate change effects on livestock |
| Rensis & Scaramuzzi (2003) | Heat stress and reproduction in dairy cows |
| West (2003) | Heat stress effects on dairy production |
| Ferreira et al. (2017) | Thermal comfort for dairy cattle on pasture (EMBRAPA Cerrados Doc.342) |
| Hott et al. (2022) | Territorial management in dairy supply chain |
| Zoccal et al. (2011) | Diagnosis of national dairy farming |
| IBGE PPM (2021) | Municipal livestock survey via SIDRA |

## See Also

- [[thi-temperature-humidity-index]]
- [[thermal-stress-dairy]]
- [[embrapa]]
- [[inmet]]
- [[ibge-ppm]]
- [[idw-interpolation]]
