# Post-hoc acquisition benchmark extension

This folder contains compact reproducibility materials for the additional acquisition benchmarks reported after the original 84-case held-out Active-versus-Space evaluation.

## Status

These analyses reuse the already-consumed 84 FEM fields. They are therefore **post-hoc comparative benchmarks**, not a new independent validation set. The original A-optimal method, inverse estimator, candidate set, parameter bounds, six-point initialization, and final budget N=15 were not retuned using these benchmark outcomes.

## Methods

- **A-optimal**: original information-driven policy; minimizes trace of the transformed covariance proxy.
- **D-optimal**: estimator-matched information-driven policy; minimizes log-determinant of the same transformed covariance proxy.
- **Random**: retains the same six frozen initial locations and samples nine unrevealed candidates uniformly without replacement. The reported distribution uses 200 layouts.
- **Space**: original deterministic geometric maximin baseline.
- **Full grid**: uses all 956 admissible locations with the same inverse estimator; it is a dense-data reference and is not budget matched.

## Main N=15 results

- A-optimal: 84/84 joint successes.
- D-optimal: 84/84 joint successes.
- Space: 67/84 joint successes.
- Random (200-layout ensemble): median 70/84; P10-P90 64/84-78/84; observed range 61/84-82/84; no layout reached 84/84.
- Full grid: 84/84 joint successes.

The main scientific interpretation is that the strongest separation is between information-driven OED and uninformed/geometric sparse placement, rather than unique superiority of the A-optimal scalar criterion.

## Files

- `POSTHOC_BENCHMARK_TABLE5.csv` — compact values used for the manuscript benchmark table.
- `RANDOM200_DISTRIBUTION_SUMMARY.csv` — distribution-level summary across 200 Random layouts.
- `RANDOM200_CONVERGENCE_BY_PREFIX.csv` — convergence summaries for prefixes of 10, 20, 50, 100, 150, and 200 layouts.
- `RANDOM200_PER_CASE_SUCCESS.csv` — success frequency of each held-out case across the 200 Random layouts.
- `protocols/RANDOM200_PROTOCOL_FROZEN_2026-09-21.txt` — protocol for extending the Random ensemble to 200 layouts.
- `scripts/aggregate_random200.py` — aggregation script for the Random outputs.

The complete per-layout and per-case Random ensemble, together with the D-optimal and full-grid casewise tables, is intended for the next Zenodo archival version because the compact GitHub repository does not include all large derived files.
