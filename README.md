# Active Surface-Potential Measurement Design for Buried Grounding Electrodes

Reproducibility companion for the manuscript:

**Active Surface-Potential Measurement Design for Physics-Informed Reconstruction of Buried Grounding Electrodes**

Author: Alexandre Giacomelli Leal

## Scope

This repository/package preserves the frozen numerical protocols, MATLAB implementations, deterministic DOE provenance, paper-level result tables, and a portable Python path for checking the main reported claims and regenerating the principal figures.

The scientific chronology is intentionally preserved:

- 16 cases were used as a fixed development sentinel.
- The final measurement budget was frozen at **N = 15** after the predeclared seven-layout seed-robustness test.
- The remaining 84 cases were evaluated once and are **consumed**.
- The additive-noise Monte Carlo experiment was defined and frozen only **after** the held-out results had been disclosed; it is secondary and must not be described as a new independent held-out validation.
- No scripts in this package should be used to retrospectively retune the frozen method and then relabel the result as the original held-out experiment.

## Key archived results

At the frozen final budget N=15:

- Active: 84/84 joint success.
- Deterministic space filling: 67/84 joint success.
- N=10 also showed 84/84 Active success, but N=15 remains the predeclared final budget.

Post-held-out additive potential-noise stress:

- 0.5% RMS: Active 98.97%, Space 18.65%.
- 1.0% RMS: Active 93.77%, Space 6.94%.

## Repository layout

- `src/fem/` — FEM convergence and surrogate-development MATLAB scripts.
- `src/active_sampling/` — frozen v5-M80 active/space and seed-robustness scripts.
- `src/final_validation/` — one-shot final held-out evaluator.
- `src/noise_stress/` — frozen post-held-out Monte Carlo noise-stress scripts.
- `protocols/` — frozen final and noise-stress protocol records.
- `data/doe/` — deterministic DOE reconstruction and archived 84-case checkpoint.
- `data/heldout_final/` — result tables sufficient to reproduce clean held-out figures/tables.
- `data/seed_robustness/` — seed robustness summaries and frozen decision.
- `data/noise_stress/` — post-held-out noise summaries.
- `data/example_case12/` — one full 956-point FEM field plus Active/Space selections used for the illustrative spatial figure.
- `scripts/` — portable validation, DOE reconstruction, and figure reproduction.

## Quick verification

Python 3.11+ is recommended.

```bash
python -m pip install -r requirements.txt
python scripts/reconstruct_master100_doe.py
python scripts/validate_results.py
python scripts/reproduce_all_figures.py
```

The validation script checks the principal numerical claims directly from the archived result tables.

## MATLAB/COMSOL environment

The frozen MATLAB studies were run with MATLAB R2025b. The FEM reference model used COMSOL Multiphysics 5.3 with LiveLink for MATLAB.

The paper-level result tables and all principal plots can be reproduced **without COMSOL** using the included derived CSV files. Re-executing the FEM generation itself requires the original COMSOL model and licensed COMSOL environment.

## Gauge-aware convergence metric

The historical v1.2 convergence script removes a single additive potential-reference shift:

```matlab
shift = mean(va-vb);
gauge_rel = norm((va-vb)-shift)/max(norm(vb),eps);
```

Thus the reported percentage is `100*gauge_rel`. This exact definition was recovered from the archived frozen script, not reconstructed retrospectively.

## Data scope

This GitHub-ready package contains derived data needed to reproduce the paper's reported tables and principal figures, plus a complete 956-point field for the illustrative case 12. It does **not** contain all 84 full COMSOL surface-field CSVs. Those full fields are best archived as a separate Zenodo dataset if desired because they are generated model outputs rather than source code.

## License

Code and bundled derived data are released under the MIT License unless a file states otherwise.

## Citation

See `CITATION.cff`. After Zenodo deposition, add the issued DOI to both `CITATION.cff` and the manuscript Data Availability statement.
