# Reproducibility publication checklist

Repository target:
https://github.com/Alexandregiacomellileal/active-surface-potential-grounding

Release target:
v1.0.0

Recommended sequence
--------------------
1. Create an empty PUBLIC GitHub repository named:
   active-surface-potential-grounding
   Do not initialize it with README, .gitignore, or license if ChatGPT will populate it.

2. Populate the repository with the contents of the GitHub-ready package.

3. Confirm on GitHub:
   - README renders correctly.
   - LICENSE is MIT.
   - CITATION.cff is detected by GitHub.
   - scripts/reconstruct_master100_doe.py runs.
   - scripts/validate_results.py returns PASS.
   - scripts/reproduce_all_figures.py regenerates the six paper-level figures.

4. Create GitHub release/tag:
   v1.0.0

5. Zenodo:
   - Sign in to Zenodo.
   - Connect GitHub in Zenodo account settings.
   - Enable archiving for this repository.
   - Create/publish GitHub release v1.0.0.
   - Verify the Zenodo record metadata using zenodo_metadata.json.
   - Publish the Zenodo record and obtain the version DOI.

6. After the DOI exists:
   - update CITATION.cff with the DOI;
   - update docs/DATA_AVAILABILITY_TEMPLATE.txt;
   - update the manuscript Data Availability statement;
   - optionally add a Zenodo DOI badge to README.md.

Scientific integrity
--------------------
- N=15 remains the predeclared final budget.
- The 84 final cases are consumed.
- The post-held-out noise experiment remains secondary.
- No new tuning should be presented as part of the original independent held-out validation.
