# Physical validation and locked replay release candidate (v1.1.0)

This package extends the public reproducibility core for the manuscript **Active Surface-Potential Measurement Design for Physics-Informed Reconstruction of Buried Grounding Electrodes**.

It combines two historically distinct, preserved packages:

1. `fullgrid/` — the deterministic post-audit full-grid physical inversion reproducibility package.
2. `locked_replay/` — the exact post-field/post-audit locked retrospective sequential replay frozen on 2026-09-13.

The original measured workbook is retained at repository root as `comparacao_real_MTR1522_D020_D030_D040_FINAL.xlsx`.

## Scientific-status guardrails

- The full-grid physical inversion is a post-audit reproducibility rerun of the physical v5-M80 surrogate and reproduces the archived manuscript estimates to numerical precision.
- The locked sparse replay is **retrospective transfer evidence**, not independent prospective field validation. The complete field maps and exploratory replay outcomes existed before the locked replay protocol was frozen.
- The clean 84-case numerical held-out evaluation remains the study's primary independent numerical evaluation.

## Verified values

Full-grid reconstruction (true depths 0.20, 0.30, 0.40 m):

- `d_hat = 0.189860, 0.286498, 0.380795 m`
- mean relative depth error = `4.790688%`
- maximum endpoint error = `0.027401 m`

Locked retrospective replay at N=15:

- Active mean relative depth error = `0.585237%`
- Space mean relative depth error = `71.388794%`
- Active mean endpoint error = `0.093079 m`
- Space mean endpoint error = `0.212909 m`

## Reproduction

Full-grid package:

```bash
cd physical_validation/fullgrid
python -m pip install -r requirements.txt
python src/reproduce_fullgrid_main.py
```

Locked replay package:

```bash
cd physical_validation/locked_replay
python run_locked_field_replay_v1.py preflight --pkg .
python run_locked_field_replay_v1.py run --pkg .
```

The locked replay reproduces the archived CSV/JSON outputs byte-for-byte when run with the frozen inputs and script.

See `PROVENANCE.md` and the package-level SHA-256 manifests for the frozen audit trail.
