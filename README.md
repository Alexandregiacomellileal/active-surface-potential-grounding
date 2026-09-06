# Active Surface-Potential Measurement Design for Buried Grounding Electrodes

Reproducibility companion for the manuscript:

**Active Surface-Potential Measurement Design for Physics-Informed Reconstruction of Buried Grounding Electrodes**

Author: Alexandre Giacomelli Leal

## Scope

This public GitHub repository preserves the **core reproducibility layer** of the study: frozen scientific protocols, the deterministic DOE provenance, the gauge-aware FEM convergence code, the M1 and segmented-surrogate diagnostics, the frozen v5-M80 inverse/acquisition core, final paper-level summaries, and portable Python checks.

A larger **Zenodo-ready v1.0.0 archive** is maintained separately for deposition. It additionally contains the larger historical final/seed runner files, casewise N=15 tables, the full 956-point illustrative case-12 field, and publication-figure assets.

The scientific chronology is intentionally preserved:

- 16 cases were used as a fixed development sentinel.
- The final measurement budget was frozen at **N = 15** after the predeclared seven-layout seed-robustness test.
- The remaining 84 cases were evaluated once and are **consumed**.
- The additive-noise Monte Carlo experiment was defined and frozen only **after** the held-out results had been disclosed; it is secondary and must not be described as a new independent held-out validation.
- No material in this repository may be used to retrospectively retune the frozen method and relabel the result as the original held-out experiment.

## Key archived results

At the frozen final budget **N=15**:

- Active: **84/84** joint success.
- Deterministic space filling: **67/84** joint success.
- N=10 also showed 84/84 Active success, but N=15 remains the predeclared final budget.

Post-held-out additive potential-noise stress:

- 0.5% RMS: Active **98.97%**, Space **18.65%**.
- 1.0% RMS: Active **93.77%**, Space **6.94%**.

## Public GitHub layout

- `src/fem/` — gauge-aware FEM convergence audit, M1 ceiling diagnostic, and segmented-surrogate diagnostic.
- `src/noise_stress/` — frozen v5-M80 inverse/acquisition core, zero-noise parity preflight, restart-safe noise runner, and summarizer.
- `protocols/` — frozen final held-out and post-held-out noise-stress protocols.
- `data/doe/` — deterministic DOE reconstruction, Development-16/Held-out-84 tables, and archived 84-case FEM-generation checkpoint.
- `data/heldout_final/` — clean final summary-by-budget and paired N=15 results.
- `data/seed_robustness/` — seven-layout seed-robustness summary and predeclared freeze decision.
- `data/noise_stress/` — post-held-out noise summaries and paired comparison.
- `scripts/` — portable DOE reconstruction, numerical-claim validation, and public-core figure reproduction.
- `docs/` — scientific chronology, Data Availability template, and GitHub/Zenodo publication checklist.

## Quick verification

Python 3.11+ is recommended.

```bash
python -m pip install -r requirements.txt
python scripts/reconstruct_master100_doe.py
python scripts/validate_results.py
python scripts/reproduce_all_figures.py
```

`validate_results.py` checks the main paper claims directly from the archived public result tables. `reconstruct_master100_doe.py` authenticates the deterministic 100-case design against the archived 84-case checkpoint.

The public-core figure script regenerates the figures supported by the compact GitHub tables. It automatically skips figures that require the larger casewise/full-field files; those files are included in the complete Zenodo-ready archive.

## MATLAB/COMSOL environment

The frozen MATLAB studies were run with MATLAB R2025b. The FEM reference model used COMSOL Multiphysics 5.3 with LiveLink for MATLAB.

Paper-level numerical claims can be checked from the derived CSV tables **without COMSOL**. Re-executing the FEM generation itself requires the original COMSOL model and a licensed COMSOL environment.

## Frozen v5-M80 acquisition core

The file `src/noise_stress/paper1_v5M80_noise_task_v10.m` contains the frozen estimator/acquisition core copied from the final held-out evaluator. It includes:

- M=80 equipotential segmented surrogate;
- discrete Voronoi-domain weighting and profiled additive `b0`;
- current local Jacobian with nuisance-offset column;
- A-optimal trace in endpoint-x, endpoint-y, and depth coordinates;
- deterministic geometric maximin baseline;
- the frozen multi-start/checkpoint nonlinear inverse logic.

The 1% clean-field-RMS `sigma_design` used in the inverse objective is a fixed normalization/design scale. It is **not** a measurement-noise robustness claim.

## Gauge-aware convergence metric

The historical v1.2 convergence script removes a single additive potential-reference shift:

```matlab
shift = mean(va-vb);
gauge_rel = norm((va-vb)-shift)/max(norm(vb),eps);
```

Thus the reported percentage is `100*gauge_rel`. This exact definition comes from the archived frozen script rather than a retrospective reconstruction.

## Data scope

GitHub intentionally contains the compact, reviewable core and derived tables needed to verify the principal claims. The complete Zenodo-ready archive contains additional historical runners and larger derived/full-field files. The full corpus of all 84 COMSOL-generated 956-point fields is not required for the portable summary checks and may be deposited separately if requested by the journal/editor.

## License

Code and bundled derived data are released under the MIT License unless a file states otherwise.

## Citation

See `CITATION.cff`. After the Zenodo release is published, the issued DOI will be added to `CITATION.cff`, this README, and the manuscript Data Availability statement.
