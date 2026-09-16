# Active Surface-Potential Measurement Design for Buried Grounding Electrodes

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.22797592.svg)](https://doi.org/10.5281/zenodo.22797592)

Reproducibility companion for the manuscript:

**Active Surface-Potential Measurement Design for Physics-Informed Reconstruction of Buried Grounding Electrodes**

Author: Alexandre Giacomelli Leal

## Scope

This repository preserves the numerical reproducibility core and the physical proof-of-concept materials supporting the revised manuscript. The numerical held-out and post-held-out noise materials remain unchanged from the archived baseline release v1.0.1. Version **v1.1.0** adds the physical provenance, full-grid reconstruction materials, map-metric reproduction, and the locked retrospective N=15 replay protocol and principal result tables.

The archived v1.1.0 release is available on Zenodo under the version-specific DOI **10.5281/zenodo.22797592**. The previous v1.0.1 numerical baseline remains archived under DOI **10.5281/zenodo.22547701**.

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

The physical material is under `physical_validation/`. The source workbook `comparacao_real_MTR1522_D020_D030_D040_FINAL.xlsx`, containing the three 17x17 MTR-1522 field campaigns, remains at repository root.

Version v1.1.0 contains:

- frozen v17 provenance records;
- deterministic full-grid v5-M80 protocol, archived reconstruction results, sensitivity result, and a workbook-based reproducer;
- physical map-comparison metric reproduction, including the reference-normalized `R2_ref` convention;
- the locked retrospective sequential Active-vs-Space replay protocol, preflight/hash records, N=15 results, all-checkpoint results, paired comparison, summary, and exact selected-point sequence.

The complete byte-identical replay archive, including the executable frozen replay script and exact exported field CSV inputs, is preserved in the v1.1.0 Zenodo archival package.

The locked replay was frozen and hashed before its own outcomes were computed, but the complete physical maps and earlier exploratory analyses were already known. It is therefore reported as **post-field/post-audit retrospective transfer evidence**, not prospective or independent field validation.

At N=15, the locked replay gives mean relative depth error 0.585% for Active versus 71.39% for Space, and mean endpoint error 0.0931 m versus 0.2129 m, respectively. The interpretation guardrail is preserved in `physical_validation/locked_replay/RESULT_NOTE.md`.

## Repository layout

- `src/fem/` — gauge-aware FEM convergence audit, M1 ceiling diagnostic, and segmented-surrogate diagnostic.
- `src/noise_stress/` — frozen v5-M80 numerical inverse/acquisition core and noise-stress tooling.
- `protocols/` — frozen numerical held-out and post-held-out protocols.
- `data/` — deterministic DOE, held-out, seed-robustness, and noise-stress tables.
- `scripts/` — portable numerical verification and figure-reproduction scripts.
- `docs/` — chronology and reproducibility documentation.
- `physical_validation/fullgrid/` — physical full-grid inversion protocol, results, and reproducer.
- `physical_validation/locked_replay/` — locked retrospective sparse replay protocol, audit records, and principal results.
- `physical_validation/reproduce_physical_map_metrics.py` — physical map metric reproducer using the source workbook.

## Quick numerical verification

Python 3.11+ is recommended.

```bash
python -m pip install -r requirements.txt
python scripts/reconstruct_master100_doe.py
python scripts/validate_results.py
python scripts/reproduce_all_figures.py
python physical_validation/reproduce_physical_map_metrics.py
```

The full-grid physical inverse can be rerun with:

```bash
python physical_validation/fullgrid/src/reproduce_fullgrid_main.py
```

The full-grid calculation runs 72 deterministic starts for each of three campaigns and may take several minutes.

## MATLAB/COMSOL environment

The frozen MATLAB studies were run with MATLAB R2025b. The FEM reference model used COMSOL Multiphysics 5.3 with LiveLink for MATLAB.

Paper-level numerical claims can be checked from derived CSV tables without COMSOL. Re-executing the FEM generation itself requires the original COMSOL model and a licensed COMSOL environment.

## Data scope

The repository contains the compact numerical reproducibility core and the physical proof-of-concept material. The complete corpus of all 84 COMSOL-generated 956-point fields is not included in the compact public archive and may be deposited separately if requested by the journal/editor.

## License

Code and bundled derived data are released under the MIT License unless a file states otherwise.

## Citation

**Leal, Alexandre Giacomelli. Active Surface-Potential Measurement Design for Physics-Informed Reconstruction of Buried Grounding Electrodes: Reproducibility Package, v1.1.0. Zenodo. https://doi.org/10.5281/zenodo.22797592**
