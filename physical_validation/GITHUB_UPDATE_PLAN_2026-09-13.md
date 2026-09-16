# GitHub update plan from frozen v17

Repository: `Alexandregiacomellileal/active-surface-potential-grounding`  
Default branch: `main`  
Repository HEAD at freeze: `118e165aa223f2831dd89ef1c62b5d7773fb778c`  
README blob SHA at freeze: `fd5a7a724b8125f56c2c9a724d2a904b0ae88311`  
Current Zenodo DOI referenced by the manuscript/repository: `10.5281/zenodo.22547701` (v1.0.1 baseline)

## Current repository state at freeze

The README at freeze documents the numerical held-out and noise-stress claims, but does not yet contain the complete locked physical replay package/results now frozen in manuscript v17.

## Future synchronized update

When updating GitHub, do not overwrite historical frozen numerical records. Add the physical material as a clearly secondary/post-field package, including the three physical field datasets, frozen replay protocol/preflight/hashes, replay implementation and derived results.

Preserve the distinction:

- full-grid physical maps -> external observability/model-transfer check;
- locked N=15 replay -> post-field/post-audit retrospective transfer evidence;
- not prospective field validation.

If a new archival release is made, update `CITATION.cff`, `zenodo_metadata.json`, README version text, and Zenodo metadata consistently. Do not reuse the old v1.0.1 release label for a package containing the new physical replay unless the archival record is actually versioned accordingly.

## Key results to expose

- Full-grid field maps: MAPE 5.34%, 4.39%, 5.90%; correlations 0.951, 0.958, 0.913.
- Full-grid v5-M80 inversion: mean relative depth error 4.79%; endpoint errors <0.028 m; orientation errors <0.35 deg.
- Locked N=15 replay: mean depth relative error 0.585% Active vs 71.39% Space; mean endpoint error 0.0931 m vs 0.2129 m; Active smaller endpoint/depth/orientation error in all 3 campaigns; secondary 10% depth criterion Active 3/3 vs Space 0/3.

## Reviewer-facing note

The locked replay was frozen/hashed before its own outcomes were computed, but the complete field maps and earlier exploratory replay outcomes were already known. Therefore it is stronger than an exploratory post-hoc replay but still not an independent prospective experiment.
