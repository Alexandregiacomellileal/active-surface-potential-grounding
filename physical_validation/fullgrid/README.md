# Physical full-grid v5-M80 reproducibility rerun

This directory is a reproducibility companion for the **secondary physical full-grid inversion** in the manuscript. It is a post-audit rerun; it does not claim recovery of undocumented historical physical-scale optimizer settings.

The recovered frozen v5-M80 forward formulation was retained. The physical solver protocol was then made explicit and deterministic, and it reproduced the archived estimates to numerical precision.

## Data

The public reproducer reads the source workbook `comparacao_real_MTR1522_D020_D030_D040_FINAL.xlsx` stored at repository root. It extracts the 289 retained MTR-1522 readings for each nominal depth directly from the raw-data sheets. No smoothing, interpolation, outlier exclusion, or imputation is applied.

The frozen Drive/Zenodo archival package also preserves exported CSV copies and their SHA-256 provenance.

## Fixed physical adaptation

- segmented surrogate v5, `M = 80`;
- homogeneous reference `rho = 100 ohm m`;
- rod radius `rc = 0.006 m` from the measured 12-mm diameter;
- probe insertion `hP = 0.03 m`;
- equipotential segment currents solved at axis depth `d`;
- observation kernel uses effective vertical separation `d-hP`;
- unknowns `L`, `phi`, and `d`; additive offset profiled analytically.

## Main inverse protocol

- `L in [1.0, 4.0] m`;
- `d in [0.05, 0.80] m`;
- `phi` circular over `[0,360 deg)`;
- 72 deterministic starts: the 25%, 50%, and 75% interior positions of the `L` and `d` intervals crossed with `phi = 0:45:315 deg`;
- Nelder-Mead;
- quadratic bound penalty `1e8`;
- `xatol = 1e-8`, `fatol = 1e-10`;
- maximum 3000 iterations and 6000 function evaluations per start.

The archived main result is in `results/physical_fullgrid_reconstruction.csv`. The mean relative depth error is **4.790688%** and the maximum endpoint error is **0.027401 m**.

## Re-run

Python 3.11+ is recommended. From repository root:

```bash
python -m pip install -r requirements.txt
python physical_validation/fullgrid/src/reproduce_fullgrid_main.py
```

The calculation runs 72 deterministic starts for each of the three campaigns and can take several minutes depending on the machine. It writes `reproduced_main.csv` and `reproduced_aggregate.json` under `physical_validation/fullgrid/results/` without overwriting the archived result files.

See `VALIDATION_NOTE.md` for the audit chronology.
