---
title: "THI — Temperature and Humidity Index"
type: concept
created: 2026-04-15
updated: 2026-04-15
sources: ["ART+050_BJAER_JAN_2023.pdf"]
tags: [thermal-stress, dairy, methodology, climate-risk]
---

# THI — Temperature and Humidity Index

The **Temperature and Humidity Index** (THI; Portuguese: **Índice de Temperatura e Umidade**, ITU) is the most widely used metric for evaluating thermal comfort conditions in dairy cattle. It combines air temperature and relative humidity into a single dimensionless value.

## Formula

Buffington et al. (1977):

```
THI = 0.8 × Tbs + UR × (Tbs − 14.3) / 100 + 46.3
```

Where:
- `Tbs` = dry bulb temperature (°C)
- `UR` = relative humidity (%)

## Classification Thresholds

Du Preez et al. (1990), used as the standard in Brazilian dairy research:

| THI Range | Condition | Impact |
|---|---|---|
| ≤ 70 | Normal comfort | No production impact expected |
| 70–72 | Alert | Mild stress, monitor animals |
| 72–78 | Alert with restrictions | Milk production decline begins |
| 78–82 | Danger | Significant production and health risk |
| > 82 | Emergency | Severe heat stress, mortality risk |

The critical threshold for dairy production decline is **THI ≥ 72** ([[andrade-2023-thi-maps-southeast-brazil|Andrade et al. 2023]]; Kemer et al. 2020; Santana et al. 2020).

## Relevance to ZARC

THI is a strong candidate index for the **climate risk dimension** of dairy zoning. It can be computed directly from INMET station data (temperature + humidity) and spatially interpolated to produce continuous risk surfaces. [[andrade-2023-thi-maps-southeast-brazil|Andrade et al. (2023)]] demonstrated this for southeastern Brazil using IDW⁴ interpolation.

## Limitations

- THI captures temperature × humidity interaction but **does not account for solar radiation or wind speed**, which also affect heat load.
- THI varies within a day — monthly/annual averages may mask acute stress events.
- Thresholds are breed-dependent: Zebu tolerate higher THI than Holstein (see [[thermal-stress-dairy]]).

## See Also

- [[thermal-stress-dairy]]
- [[andrade-2023-thi-maps-southeast-brazil]]
- [[inmet]]
- [[idw-interpolation]]
