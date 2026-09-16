# Physical full-grid v5-M80 reproducibility rerun

This directory is a self-contained reproducibility companion for the **secondary physical full-grid inversion** in the manuscript. It is a post-audit rerun; it does not claim recovery of the historical physical-scale optimizer bounds or multistart settings.

The recovered frozen v5-M80 forward formulation was retained. The physical solver protocol was then made explicit and deterministic, and it reproduced the archived Table-10 estimates to numerical precision.

## Data

`data/physical_D020.csv`, `physical_D030.csv`, and `physical_D040.csv` contain the 289 raw grid positions for each depth, the retained MTR-1522 resistance, the campaign reference resistance, and `Z_field = R_ref - R_MTR`.

No smoothing, interpolation, or point exclusion is applied.

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

## Broader-bound audit

A reporting-only sensitivity rerun uses `L in [0.6,4.5] m` and `d in [0.04,1.0] m` with the same multistart structure. It produces the same estimates at the precision reported in the manuscript. Archived results are in `results/physical_fullgrid_sensitivity_broader_bounds.csv`.

## Re-run

Python 3.11+ is recommended:

```bash
python -m pip install -r requirements.txt
python src/reproduce_fullgrid_main.py
python src/run_broader_bounds_sensitivity.py
```

The verifier writes new files named `reproduced_*.csv/json` so that the archived results are not overwritten.

See `VALIDATION_NOTE.md` for the audit chronology and the direct comparison between the archived and reproduced estimates.
