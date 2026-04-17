---
title: "Boonkum et al. (2024) — Heat Stress Impact on Thai–Holstein Dairy Cattle"
type: source
created: 2026-04-17
updated: 2026-04-17
sources: ["Impact of Heat Stress on Milk Yield.pdf"]
tags: [thermal-stress, dairy, milk-production, methodology, climate-risk]
---

# Boonkum et al. (2024) — Heat Stress Impact on Thai–Holstein Dairy Cattle

## Bibliographic Metadata

| Field | Value |
|---|---|
| **Title** | Impact of Heat Stress on Milk Yield, Milk Fat-to-Protein Ratio, and Conception Rate in Thai–Holstein Dairy Cattle: A Phenotypic and Genetic Perspective |
| **Authors** | Wuttigrai Boonkum, Watcharapong Teawyoneyong, Vibuntita Chankitisakul, Monchai Duangjinda, Sayan Buaban |
| **Journal** | Animals (MDPI) |
| **Volume/Issue** | 14, 3026 |
| **Date** | 2024-10-19 |
| **DOI** | [10.3390/ani14203026](https://doi.org/10.3390/ani14203026) |
| **Affiliation** | Khon Kaen University, Thailand; Network Center for Animal Breeding and Omics Research; Bureau of Livestock Development |
| **Keywords** | heat tolerance, genetic parameter, multiple traits, Thai dairy cattle |
| **License** | CC BY 4.0 |

## Summary

A large-scale phenotypic and **genetic analysis** of heat stress effects on three dairy traits — milk yield (MY), milk fat-to-protein ratio (FPR), and conception rate (CR) — in crossbred Thai–Holstein dairy cattle. This is one of the few studies that simultaneously considers production, milk composition, and reproduction under heat stress.

### Data

- **168,124 records** for MY and FPR; **21,278 records** for CR
- 21,278 first-lactation crossbred Thai–Holstein cows
- Period: **1999–2017** (Bureau of Biotechnology in Livestock Production, Thailand)
- Climate: Thai Meteorological Department — daily temperature and RH every 3 hours, matched to nearest postal code
- **Three breed groups (BG)** by Holstein genetics percentage: BG1 (<87.5%), BG2 (87.5–93.6%), BG3 (>93.7%)

### THI Formula (NOAA)

```
THI = (1.8 × Temp + 32) − (0.55 − 0.0055 × RH) × (1.8 × Temp − 26)
```

This is a different formula from the Buffington (1977) equation used in Brazilian studies (see [[thi-temperature-humidity-index]]). The NOAA formula is widely used in international genetic evaluation studies.

### Key Findings

#### THI Threshold

- **THI = 76** identified as the threshold point of heat stress for all three traits (lowest −2logL and AIC)
- At THI76: negative regression slopes for MY (−0.284), FPR (−0.094), CR (−0.089)
- This is **higher than most reported thresholds** (typically 68–72) — explained by the Thai–Holstein crossbreeding program incorporating heat-tolerant local breeds
- THI76 corresponds to: **25.6–26.9°C** and **RH 60.0–68.6%**

#### Heritability Under Heat Stress

| Trait | h² at THI76 | h² at THI80 | Interpretation |
|---|---|---|---|
| Milk yield | 0.380 ± 0.032 | 0.377 ± 0.030 | Moderate; stable under stress — amenable to genetic selection |
| Milk FPR | 0.293 ± 0.021 | 0.293 ± 0.020 | Moderate; stable — selection possible but slower |
| Conception rate | 0.032 ± 0.001 | 0.026 ± 0.001 | Very low; drops further under stress — dominated by environment |

#### Genetic Correlations (at THI76)

| | MY | Milk FPR | CR | Heat Tolerance |
|---|---|---|---|---|
| **MY** | — | −0.24 | −0.53 | **−0.26** |
| **Milk FPR** | −0.04 (env) | — | 0.48 | **−0.48** |
| **CR** | −0.25 (env) | 0.38 (env) | — | **−0.49** |

**Key antagonism**: genetic correlations between all three production/reproduction traits and heat tolerance are **negative** — selecting for higher production genetically undermines heat tolerance, and vice versa.

#### Decline Rates by Breed Group (per unit THI increase)

| Trait | BG1 (<87.5% Holstein) | BG3 (>93.7% Holstein) | Pattern |
|---|---|---|---|
| MY at THI76 | −0.046 kg | −0.086 kg | Higher Holstein % → faster decline |
| MY at THI80 | −0.066 kg | −0.218 kg | 43.5% vs 153.5% increase in decline rate |
| CR at THI76 | −0.027% | −0.102% | |
| CR at THI80 | −0.050% | −0.179% | CR most sensitive; 75.5% increase in decline |

**More Holstein genetics = more vulnerability to heat stress** across all traits, with CR showing the steepest decline.

### Methodology

- **Multiple-trait threshold-linear random regression model** (Bayesian, Gibbs sampling)
- 500,000 iterations, 50,000 burn-in, every 10th sample retained
- Software: THRGIBBS1F90 / POSTGIBBSF90
- Fixed effects: herd × test-month × test-year (MY/FPR), herd × year × season (CR), age at first calving, months in milk, THI regression by BG
- Random effects: animal (with/without THI), permanent environment, herd, service sire (CR only)

## Relevance to ZARC Research

- **THI threshold of 76** vs the commonly cited 72 highlights that thresholds are breed- and population-dependent — important for Brazilian crossbred populations (Girolando, Gir × Holstein)
- The **negative genetic correlation between production and heat tolerance** (−0.26 to −0.49) has direct implications for breed selection in climate-vulnerable regions of Brazil
- **Conception rate is the most environmentally sensitive trait** (h² ≈ 0.03) — thermal stress zoning should consider reproductive impacts, not just milk yield
- The NOAA THI formula differs from the Buffington formula used in [[andrade-2023-thi-maps-southeast-brazil]]; both are valid but produce different absolute values for the same conditions

## See Also

- [[thi-temperature-humidity-index]]
- [[thermal-stress-dairy]]
- [[andrade-2023-thi-maps-southeast-brazil]]
- [[dias-souza-2026-dairy-climate-minas-gerais]]
