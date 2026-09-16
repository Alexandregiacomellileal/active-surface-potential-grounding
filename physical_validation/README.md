# Physical validation release candidate

This directory stages the physical proof-of-concept materials for the revised manuscript **Active Surface-Potential Measurement Design for Physics-Informed Reconstruction of Buried Grounding Electrodes**.

## Scientific scope

The physical material has two distinct roles:

1. **Full-grid field maps and full-grid inversion** — external observability/model-transfer evidence using the complete 17x17 measured maps at nominal depths 0.20, 0.30, and 0.40 m.
2. **Locked N=15 replay** — a post-field, post-audit retrospective sequential replay of the frozen Active-vs-Space acquisition logic. Its protocol, script, data, and results are hash-audited. It is **not** prospective or independent field validation.

The complete field maps and earlier exploratory analyses were already known before the locked replay protocol was created. The replay was then frozen and hashed before its own outcomes were computed. This distinction is preserved throughout the release materials.

## Contents

- `fullgrid/` — deterministic v5-M80 full-grid inversion protocol, data, scripts, archived results, sensitivity diagnostics, and checksums.
- `locked_replay/` — frozen sequential replay protocol, preflight record, input field CSVs, exact replay script, selected-point sequences, checkpoint results, N=15 paired results, summary, and SHA-256 records.
- `reproduce_physical_map_metrics.py` — reproduces the physical map comparison metrics from the measured and ideal/reference columns.
- `MAP_METRICS_NOTE.md` — documents the reference-normalized squared-error score used for the archived R²-like comparison.
- `PROVENANCE.md` — links this public candidate to the frozen 2026-09-13 archive and source workbook.

The source workbook `comparacao_real_MTR1522_D020_D030_D040_FINAL.xlsx` remains at the repository root; its SHA-256 is recorded in the provenance files.

## Release status

This branch is a **candidate** for the next GitHub/Zenodo archival version. The existing DOI 10.5281/zenodo.22547701 corresponds to the earlier v1.0.1 numerical baseline and must not be described as already containing this physical package. A new Zenodo version should be created after this branch is finalized.
