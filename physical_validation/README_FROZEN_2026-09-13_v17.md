# Frozen manuscript/reproducibility snapshot — 2026-09-13 (v17)

This file records the historical frozen reference used to reconstruct the physical release candidate for **Active Surface-Potential Measurement Design for Physics-Informed Reconstruction of Buried Grounding Electrodes**.

Freeze date: **2026-09-13**.

## Physical evidence preserved at freeze

Three complete 17x17 MTR-1522 maps (289 positions per nominal depth; 867 retained readings total) were acquired for a 2.40-m horizontal copper-clad steel rod at axis depths 0.20, 0.30, and 0.40 m.

- Full-grid MAPEs: 5.34%, 4.39%, 5.90%.
- Pearson correlations: 0.951, 0.958, 0.913.
- Full-grid v5-M80 mean relative depth error: 4.79%.
- Endpoint errors: <0.028 m.
- Orientation errors: <0.35 deg.

The locked retrospective sequential replay has protocol id `LOCKED_FIELD_REPLAY_2026-09-13_v1`. At N=15 its mean relative depth error was 0.585237% for Active and 71.388794% for Space; mean endpoint error was 0.093079 m and 0.212909 m, respectively.

## Interpretation guardrail

The locked replay is **POST-FIELD, POST-AUDIT, LOCKED RETROSPECTIVE SEQUENTIAL REPLAY**. It is transfer evidence, not prospective or independent field validation. The complete field maps and earlier exploratory analyses were already known before the replay protocol was frozen, although the locked protocol and inputs were hashed before its own outcomes were computed.

Do not overwrite or silently retune the frozen replay. Any future scientific change should be a new version and preserve this provenance record.
