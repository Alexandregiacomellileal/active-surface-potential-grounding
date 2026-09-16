# Physical validation release checklist

Status: candidate branch prepared; do not merge or tag until the new archival package and DOI are ready.

- [x] preserve numerical baseline history unchanged
- [x] add frozen v17 provenance records
- [x] add full-grid physical protocol, scripts, archived results, and metric-reproduction materials
- [x] add locked replay protocol, preflight/hash records, all-checkpoint results, N=15 results, paired comparison, summary, and selected-point sequence
- [x] preserve the source workbook at repository root
- [x] document the retrospective/non-prospective scientific-status guardrail
- [ ] attach the byte-identical frozen replay executable archive and exact CSV inputs to the new Zenodo version
- [ ] run one final clean-environment reproduction from the archival package
- [ ] create the new GitHub release/tag after review
- [ ] create the new Zenodo version and record the version-specific DOI
- [ ] update `CITATION.cff`, `zenodo_metadata.json`, and README DOI/version text
- [ ] update the manuscript Data Availability statement only after the new DOI is confirmed

The existing DOI `10.5281/zenodo.22547701` remains the archived v1.0.1 numerical baseline and must not be represented as already containing the new physical-validation package.
