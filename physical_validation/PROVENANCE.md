# Provenance and release audit

## Frozen source snapshot

The immutable source snapshot is `ACTIVE_SURFACE_POTENTIAL_GROUNDING_2026-09-13_V17`. The frozen record identifies GitHub commit `118e165aa223f2831dd89ef1c62b5d7773fb778c` as the public baseline before the locked physical replay was added.

Source workbook SHA-256:

`27eabc40f6ffc6f8d06095fb3ef67265a0c789bb584c6835a985966de5ee28d1`

Historical locked replay ZIP SHA-256:

`c43dc6dcdbabfe2a369e0fa85a2c9866499913ff8c5ee8d48bc3823e512f5443`

Locked replay protocol SHA-256:

`b4bac22fb22c6a5fa2e99fc21d40566e92be7e05386d87df2afdde57e9e5bdb5`

Locked replay script SHA-256:

`f0dc4cc65edaac9682d739342e76c73f18f4c12610602800a9d7639588ae300a`

## Verification performed for this release candidate

- The source workbook and historical replay ZIP hashes match the frozen `FREEZE_RECORD.json`.
- The locked replay preflight regenerated the exact archived `PREFLIGHT_PASS.json` hash.
- A clean rerun reproduced the locked replay result tables, selection sequences, and summary byte-for-byte.
- The full-grid reproducibility script was rerun and reproduced the manuscript-level estimates to numerical precision.
- The three CSV exports in the full-grid and locked-replay subpackages have identical numerical values and row ordering but different byte serialization; both are retained in their original package contexts to preserve historical hashes.

## Publication status

This directory is a release candidate. Create a new GitHub tag/release and a new Zenodo version rather than modifying the archived v1.0.1 record.
