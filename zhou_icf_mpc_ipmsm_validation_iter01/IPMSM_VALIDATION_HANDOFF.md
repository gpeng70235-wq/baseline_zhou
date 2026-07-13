# IPMSM validation handoff

## 1. Purpose

Independent evidence chain for Zhou ICF-MPC compatibility with an IPMSM; no MTPA or new controller is introduced here.

## 2. Project path

`C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_validation_iter01`

## 3. Source baselines and SHA-256

See `SOURCE_MANIFEST.sha256`, `reference/manifests/`, and `docs/baseline_inheritance_mapping.md`. Iteration 11 is a fixed source snapshot, not an authority freeze.

## 4. Git state

- branch: `ipmsm-validation-iter01`
- content commit: `92b887789c9dea449ea71be65cfbd452aee938d4`
- push status: `SUCCESS` at `2026-07-13T09:13:09+08:00`
- remote: `https://github.com/gpeng70235-wq/baseline_zhou.git`

## 5. Directory structure

Code is under `src/`, configuration under `config/`, experiments under `experiments/`, tests under `tests/`, immutable evidence under `reference/`, run artifacts under `results/<experiment>/<run_id>/` and `plots/<experiment>/<run_id>/`.

## 6. One-command run

```powershell
& 'D:\software\MATLAB R2024b\bin\matlab.exe' -batch "cd('C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_validation_iter01'); run_all_ipmsm_validation"
```

## 7. Configuration entries

`config/base_parameters.m`, `ipmsm_parameters.m`, `experiment_matrix.m`, `estimator_definitions.m`, `acceptance_thresholds.m`, `parameter_mismatch_definitions.m`, `implementation_assumptions.m`.

## 8. Experiment entries

`experiments/experiment_A0_strict_P0_regression.m` through `experiment_A8_numerical_closure.m`. A0 is the mandatory stop gate.

## 9. Result entries

All summary CSVs are in `results/summary/`; formal run `20260713_084757_ipmsm_validation` detailed artifacts are in each experiment directory.

## 10. Priority plots

`final_decision_dashboard.png`, `p0_current_pointwise_difference.png`, `ipmsm_condition_rmse_heatmap.png`, `F_estimated_vs_interval_oracle.png`, `rk4_convergence.png` under the run-scoped plot directories.

## 11. Gate state

- tests: **PASS**
- A0: **PASS**
- A1 legality: **FAIL**
- numerical closure: **PASS**

## 12. Formal conclusion

**E. 当前移植不成立** — 严格P0已通过，但六工况合法性门因高速IPMSM非法Case失败。

## 13. Unresolved questions

Hardware behavior, magnetic saturation, temperature, sensor/noise realism, mechanical speed-loop interaction, and causal estimator redesign remain outside this validation.

## 14. Excluded explanations

The project separately checks frame inheritance, Case/duration legality, queue alignment, integer-cycle THD, plant-only mismatch, offline Oracle, and RK4 refinement. See diagnostics before attributing causality.

## 15. Claims that are not allowed

Do not call ESO an innovation; do not call the Oracle online; do not translate sensitivity into temperature/saturation; do not call stress cases a real envelope; do not call Iteration 11 an authority freeze.

## 16. Single next recommendation

Resolve the failed or ambiguous gate before MTPA.

## 17. Constraints that must remain frozen

One-beat selected/queued/applied order; execution-segment midpoint frame definitions; Case 1/2/3 and Table-I policy; six-sector vector table; duration formulas; applied-voltage F history; independent d/q rectangle; original algebraic F parameters.

## 18. Reproduce this formal run

Run the command in section 6. A new run_id is intentionally generated; compare its summaries with run `20260713_084757_ipmsm_validation`. The old run is never overwritten.

## 19. GitHub remote

`https://github.com/gpeng70235-wq/baseline_zhou.git`

## 20. Reading order

1. `VALIDATION_DECISION.md`
2. `FINAL_IPMSM_VALIDATION_REPORT.md`
3. `diagnostics/p0_regression_diagnosis.md`
4. `diagnostics/residual_rootcause_evidence.md`
5. `docs/baseline_inheritance_mapping.md`
