# Final IPMSM probe report

- Run ID: `20260712_211507_428_ipmsm_probe`
- Timestamp: 2026-07-12 21:15:20
- Version: `1.1.0`
- Motor: IPMSM, `Ld=0.0008 H`, `Lq=0.0012 H`
- MATLAB path isolation: **PASS** (see `diagnostics/path_isolation_audit.md`)

## Gate status

| gate | status | detail |
|---|---:|---|
| tests | PASS | PASS |
| P0 | PASS | PASS |
| P1 | PASS | PASS |
| alpha | PASS | PASS |
| negative_id | PASS | PASS |

A failed or errored gate automatically skips every downstream experiment. Exceptions are recorded under `diagnostics/runtime_errors/`.

## Run artifacts

- **P0 degenerate regression:** `results/regression/20260712_211507_428_ipmsm_probe/metrics.csv` (1 condition(s)); plots: `plots/regression/20260712_211507_428_ipmsm_probe`

  | condition | RMSE d (A) | RMSE q (A) | mean torque (N m) | illegal | negative dwell | d/q violations | pass |
  |---|---:|---:|---:|---:|---:|---:|---:|
  | default | 0.192605 | 0.213279 | 4.55322 | 0 | 0 | 0/0 | PASS |

- **P1 saliency probe:** `results/saliency/20260712_211507_428_ipmsm_probe/metrics.csv` (1 condition(s)); plots: `plots/saliency/20260712_211507_428_ipmsm_probe`

  | condition | RMSE d (A) | RMSE q (A) | mean torque (N m) | illegal | negative dwell | d/q violations | pass |
  |---|---:|---:|---:|---:|---:|---:|---:|
  | default | 0.227372 | 0.287046 | 4.5035 | 0 | 0 | 0/0 | PASS |

- **Alpha-mode comparison:** `results/alpha_comparison/20260712_211507_428_ipmsm_probe/metrics.csv` (2 condition(s)); plots: `plots/alpha_comparison/20260712_211507_428_ipmsm_probe`

  | condition | RMSE d (A) | RMSE q (A) | mean torque (N m) | illegal | negative dwell | d/q violations | pass |
  |---|---:|---:|---:|---:|---:|---:|---:|
  | axis_specific | 0.227372 | 0.287046 | 4.5035 | 0 | 0 | 0/0 | PASS |
  | common_Ls | 0.468836 | 0.272621 | 4.56262 | 0 | 0 | 0/0 | PASS |

- **Negative-id sweep:** `results/negative_id/20260712_211507_428_ipmsm_probe/metrics.csv` (4 condition(s)); plots: `plots/negative_id/20260712_211507_428_ipmsm_probe`

  | condition | RMSE d (A) | RMSE q (A) | mean torque (N m) | illegal | negative dwell | d/q violations | pass |
  |---|---:|---:|---:|---:|---:|---:|---:|
  | id=0 A | 0.227372 | 0.287046 | 4.5035 | 0 | 0 | 0/0 | PASS |
  | id=-2 A | 0.225632 | 0.282328 | 4.63664 | 0 | 0 | 0/0 | PASS |
  | id=-4 A | 0.226392 | 0.28219 | 4.76936 | 0 | 0 | 0/0 | PASS |
  | id=-6 A | 0.235985 | 0.284917 | 4.89992 | 0 | 0 | 0/0 | PASS |


## Interpretation and limits

- P0 checks the analytical `Ld=Lq` SMPMSM limit and inherited command/constraint invariants; it does not copy historical Iteration 11 result files.
- P1 requires a measurable closed-loop saliency effect. The negative-id sweep checks the expected positive reluctance-torque gain for `Ld<Lq`.
- This is a fixed-speed, ideal-inverter simulation. Saturation, iron loss, dead time, mechanical transients, and parameter drift are outside scope.
- Review structured summaries in `results/summary/`; source provenance is in `SOURCE_MANIFEST.sha256`.
