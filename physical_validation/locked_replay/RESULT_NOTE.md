# Locked retrospective sequential field replay — result note

**Scientific status:** post-field, post-audit, locked sensitivity replay. This is **not** an independent or prospective field validation of Active-vs-Space superiority.

The protocol, script, and input datasets were hashed and checked by a preflight step before inverse outcomes were computed. No scientific choice was changed after the run.

## N = 15 results

| True depth (m) | Method | Lhat (m) | phihat (deg) | dhat (m) | Endpoint error (m) | Depth rel. error (%) |
|---:|:---|---:|---:|---:|---:|---:|
| 0.20 | Active | 2.3457 | 0.2619 | 0.2011 | 0.0554 | 0.568 |
| 0.20 | Space  | 2.4371 | 356.3700 | 0.0500 | 0.1576 | 75.000 |
| 0.30 | Active | 2.3982 | 2.4401 | 0.3033 | 0.1022 | 1.090 |
| 0.30 | Space  | 2.4452 | 355.3508 | 0.0500 | 0.2017 | 83.333 |
| 0.40 | Active | 2.3706 | 2.8367 | 0.4004 | 0.1217 | 0.098 |
| 0.40 | Space  | 2.5090 | 353.9899 | 0.1767 | 0.2794 | 55.833 |

Mean N=15 errors:

- Active: endpoint 0.09308 m; depth absolute 0.001599 m; depth relative 0.585%; orientation 1.846 deg; length 0.02850 m.
- Space: endpoint 0.21291 m; depth absolute 0.20778 m; depth relative 71.389%; orientation 4.763 deg; length 0.06380 m.
- Historical depth-relative <=10% criterion: Active 3/3; Space 0/3.
- Paired wins: Active 3/3 for endpoint, depth, and orientation; Active 2/3 for length.

## Interpretation guardrail

These results are striking but must not replace the manuscript's current caution about the physical sparse replay. The field maps and previous formulation-sensitive replay outcomes were already known before this protocol was defined. Therefore, this run is best treated as a locked **post-audit sensitivity analysis**. Its strongest use is to predeclare a future prospective field experiment using the exact same physical initialization and sequential acquisition policy.

The result also helps explain the numerical mechanism: Active selected many new points close to the electrode axis and its endpoints, whereas deterministic Space spent several measurements in the far field/corners. Under this particular locked replay formulation, that difference strongly affected depth identifiability.
