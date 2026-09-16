# Active Surface-Potential Measurement Design for Buried Grounding Electrodes

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.22547701.svg)](https://doi.org/10.5281/zenodo.22547701)

Reproducibility companion for the manuscript:

**Active Surface-Potential Measurement Design for Physics-Informed Reconstruction of Buried Grounding Electrodes**

Author: Alexandre Giacomelli Leal

## Scope

This repository preserves the numerical reproducibility core and the staged physical proof-of-concept package supporting the manuscript. The numerical held-out and post-held-out noise materials remain unchanged from the archived baseline release v1.0.1. The branch `physical-validation-release-candidate` adds the physical field datasets, full-grid reconstruction materials, and the locked retrospective N=15 replay prepared for the revised manuscript.

The existing Zenodo DOI **10.5281/zenodo.22547701** corresponds to the earlier v1.0.1 baseline. A new Zenodo version/DOI should be created only after this candidate branch is finalized and released.

## Numerical chronology

- 16 cases were used as a fixed development sentinel.
- The final measurement budget was frozen at **N = 15** after the predeclared seven-layout seed-robustness test.
- The remaining 84 cases were evaluated once and are consumed.
- The additive-noise Monte Carlo experiment was defined and frozen only after the held-out results had been disclosed; it is secondary and is not a new independent held-out validation.

## Key numerical results

At **N=15**:

- Active: **84/84** joint success.
- Deterministic space filling: **67/84** joint success.

Post-held-out additive potential-noise stress:

- 0.5% RMS: Active **98.97%**, Space **18.65%**.
- 1.0% RMS: Active **93.77%**, Space **6.94%**.

## Physical proof of concept

The staged physical package is under `physical_validation/`.

It contains:

- the three 17x17 MTR-1522 field maps for nominal depths 0.20, 0.30, and 0.40 m;
- deterministic full-grid v5-M80 reconstruction materials;
- map-comparison metric reproduction;
- a locked retrospective sequential Active-vs-Space replay at N={6,8,10,15};
- protocol, preflight, SHA-256 provenance, selected-point sequences, and result summaries.

The locked replay was frozen and hashed before its own outcomes were computed, but the complete physical maps and earlier exploratory analyses were already known. It is therefore reported as **post-field/post-audit retrospective transfer evidence**, not prospective or independent field validation.

At N=15, the locked replay gives mean relative depth error 0.585% for Active versus 71.39% for Space, and mean endpoint error 0.0931 m versus 0.2129 m, respectively. These results are preserved with explicit interpretation guardrails in `physical_validation/locked_replay/RESULT_NOTE.md`.

## Repository layout

- `src/fem/` — gauge-aware FEM convergence audit, M1 ceiling diagnostic, and segmented-surrogate diagnostic.
- `src/noise_stress/` — frozen v5-M80 numerical inverse/acquisition core and noise-stress tooling.
- `protocols/` — frozen numerical held-out and post-held-out protocols.
- `data/` — deterministic DOE, held-out, seed-robustness, and noise-stress tables.
- `scripts/` — portable numerical verification and figure-reproduction scripts.
- `docs/` — chronology and reproducibility documentation.
- `physical_validation/fullgrid/` — physical full-grid inversion package.
- `physical_validation/locked_replay/` — locked retrospective sparse replay package.
- `physical_validation/reproduce_physical_map_metrics.py` — physical map metric reproducer.

## Quick numerical verification

Python 3.11+ is recommended.

```bash
python -m pip install -r requirements.txt
python scripts/reconstruct_master100_doe.py
python scripts/validate_results.py
python scripts/reproduce_all_figures.py
```

## MATLAB/COMSOL environment

The frozen MATLAB studies were run with MATLAB R2025b. The FEM reference model used COMSOL Multiphysics 5.3 with LiveLink for MATLAB.

Paper-level numerical claims can be checked from derived CSV tables without COMSOL. Re-executing the FEM generation itself requires the original COMSOL model and a licensed COMSOL environment.

## Data scope

The repository contains the compact numerical reproducibility core and the staged physical proof-of-concept package. The complete corpus of all 84 COMSOL-generated 956-point fields is not included in the compact public archive and may be deposited separately if requested by the journal/editor.

## License

Code and bundled derived data are released under the MIT License unless a file states otherwise.

## Citation

Until the new physical-validation release is archived, the existing DOI refers to the v1.0.1 numerical baseline:

**Leal, Alexandre Giacomelli. Active Surface-Potential Measurement Design for Physics-Informed Reconstruction of Buried Grounding Electrodes: Reproducibility Package, v1.0.1. Zenodo. https://doi.org/10.5281/zenodo.22547701**
