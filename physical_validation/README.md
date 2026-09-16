# Physical validation release candidate

This directory stages the physical proof-of-concept material supporting the revised manuscript **Active Surface-Potential Measurement Design for Physics-Informed Reconstruction of Buried Grounding Electrodes**.

## Scientific status

The material under this directory is intentionally separated into two components:

1. `fullgrid/` — deterministic post-audit physical full-grid reconstruction and sensitivity checks.
2. `locked_replay/` — the post-field/post-audit locked retrospective sequential Active-vs-Space replay frozen on 2026-09-13.

The full-grid reconstruction is a physical proof of concept / model-transfer check. The sparse locked replay is **retrospective transfer evidence, not independent prospective field validation**. The complete field maps and exploratory analyses existed before the replay protocol was frozen.

The clean 84-case numerical held-out experiment remains the primary independent numerical evaluation in the study.

## Source data

The original measured workbook is preserved at repository root:

`comparacao_real_MTR1522_D020_D030_D040_FINAL.xlsx`

The three physical campaigns contain 289 retained positions each (867 retained readings total) for burial depths 0.20, 0.30, and 0.40 m.

`reproduce_physical_map_metrics.py` reads that source workbook directly and reproduces the reported map-comparison metrics. `MAP_METRICS_NOTE.md` documents the reference-normalized `R2_ref` convention used in the manuscript.

## Locked replay provenance

The reviewable GitHub material includes the protocol, preflight/hash records, all-checkpoint results, N=15 results, paired comparison, summary, and the exact selected-point sequence:

- `LOCKED_FIELD_REPLAY_PROTOCOL_v1.json`
- `PREFLIGHT_PASS.json`
- `PROTOCOL_SHA256.txt`
- `LOCK_MANIFEST_SHA256.txt`
- `RESULTS_SHA256.txt`
- `RESULT_NOTE.md`
- `locked_replay_results_all_checkpoints.csv`
- `locked_replay_results_N15.csv`
- `locked_replay_paired_N15.csv`
- `locked_replay_selection_sequences.csv`
- `locked_replay_summary.json`

The byte-identical executable replay archive, including the frozen replay script and exact exported physical CSV inputs, is preserved in the frozen v17 source package and is intended to accompany the new Zenodo archival version. This distinction is deliberate so the public GitHub history remains reviewable while the full immutable binary/archive payload is versioned on Zenodo.

## Verified manuscript values

Full-grid reconstruction:

- reconstructed depths: 0.189860, 0.286498, 0.380795 m;
- mean relative depth error: 4.790688%;
- maximum endpoint error: 0.027401 m.

Locked N=15 replay:

- Active mean relative depth error: 0.585237%;
- Space mean relative depth error: 71.388794%;
- Active mean endpoint error: 0.093079 m;
- Space mean endpoint error: 0.212909 m.

See `PROVENANCE.md`, `FREEZE_RECORD_2026-09-13_v17.json`, and the SHA-256 manifests for audit details.
