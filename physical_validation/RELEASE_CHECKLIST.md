# Physical-validation release checklist

- [x] Preserve `main` numerical baseline unchanged while staging.
- [x] Recover and record the frozen 2026-09-13 v17 provenance.
- [x] Add the physical full-grid protocol, archived reconstruction results, and workbook-based reproducer.
- [x] Add the locked replay protocol, preflight/hash records, N=15 results, all-checkpoint results, paired comparison, and interpretation guardrail.
- [x] Add the physical map-comparison metric reproducer and reference-normalized `R2_ref` convention.
- [x] Add release-candidate Data Availability wording that is explicitly not final until a new DOI exists.
- [ ] Review the draft pull request and run the public reproducibility checks from a clean clone.
- [ ] Add the complete byte-identical frozen replay archive and remaining auxiliary artifacts to the new Zenodo version.
- [ ] Create the new GitHub release/tag only after review.
- [ ] Create a new Zenodo version linked to the new GitHub release.
- [ ] Update `CITATION.cff`, `zenodo_metadata.json`, README DOI/version text, and manuscript Data Availability with the new version-specific DOI.
- [ ] Merge to `main` only after the release contents and DOI/version strategy are confirmed.

The existing DOI `10.5281/zenodo.22547701` remains the v1.0.1 numerical baseline and must not be represented as already containing the physical package.
