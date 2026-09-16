# Audit resolution note

The historical physical-scale optimizer configuration used to generate the first secondary full-grid inversion was not preserved with the field spreadsheet. The original frozen **v5-M80 forward model**, however, was recovered from the project archive.

A new deterministic physical-scale reproducibility protocol was therefore fixed without changing the v5 forward physics. The physical rod radius is 0.006 m, the probe insertion is 0.03 m, and the observation kernel uses the effective vertical separation `d - hP` while the equipotential current distribution is solved at the electrode-axis depth `d`.

With broad main bounds `L=[1.0,4.0] m` and `d=[0.05,0.80] m` and 72 systematic multistarts, the rerun reproduced the previously archived estimates to numerical precision:

| true d (m) | archived Lhat (m) | rerun Lhat (m) | archived phihat (deg) | rerun phihat (deg) | archived dhat (m) | rerun dhat (m) |
|---:|---:|---:|---:|---:|---:|---:|
| 0.20 | 2.3745874725 | 2.3745874778 | 0.2459861363 | 0.2459861020 | 0.1898601680 | 0.1898601693 |
| 0.30 | 2.3846438924 | 2.3846438964 | 0.2165358905 | 0.2165358302 | 0.2864976415 | 0.2864976386 |
| 0.40 | 2.4075704501 | 2.4075704573 | 0.3477390007 | 0.3477391186 | 0.3807945542 | 0.3807945523 |

A reporting-only audit using still broader bounds `L=[0.6,4.5] m` and `d=[0.04,1.0] m` produced estimates identical at the precision reported in the manuscript. Thus the full-grid solution is not a consequence of a narrow hidden bound choice.

This package should be described as a **post-audit reproducibility rerun**, not as recovery of the historical physical optimizer settings or as prospective field validation of sparse active acquisition.
