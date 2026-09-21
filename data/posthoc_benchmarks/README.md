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

## Files in the compact GitHub repository

- `POSTHOC_BENCHMARK_TABLE5.csv` — compact values used for the manuscript benchmark table.
- `RANDOM200_DISTRIBUTION_SUMMARY.csv` — distribution-level Random-200 summary.
- `RANDOM200_CONVERGENCE_BY_PREFIX.csv` — convergence summaries for 10, 20, 50, 100, 150, and 200 layouts.
- `../../protocols/RANDOM200_PROTOCOL_FROZEN_2026-09-21.txt` — protocol for extending the Random ensemble to 200 layouts.
- `../../scripts/summarize_random200.py` — portable aggregation script for the complete casewise Random file.

The complete `RANDOM200_ALL_CASEWISE.csv`, `RANDOM200_LAYOUT_SUMMARY.csv`, `RANDOM200_PER_CASE_SUCCESS.csv`, and casewise D-optimal/full-grid tables are intended for the v1.2.0 Zenodo archive.
