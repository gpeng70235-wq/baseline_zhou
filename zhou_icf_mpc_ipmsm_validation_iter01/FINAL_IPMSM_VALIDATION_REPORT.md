# Final Zhou ICF-MPC IPMSM validation report

- Formal run: `20260713_084757_ipmsm_validation`
- MATLAB: `24.2.0.2712019 (R2024b)`
- Decision: **E. 当前移植不成立**

## 1. One-sentence conclusion

严格P0已通过，但六工况合法性门因高速IPMSM非法Case失败。

## 2. Confirmed facts

- Mandatory tests: 24/24 passed.
- Strict P0 cycle-level gate: **PASS** across three closed-loop conditions.
- Six-condition P0/P1 legality gate: **FAIL**; illegal=1, negative dwell=NaN.
- The Iteration 11 source is a fixed validation snapshot, not an authority freeze; its own report withheld IPMSM admission.

## 3. Reasonable inferences

- IPMSM residual amplification flag: **YES**.
- P1/P0 interval-F residual ratios are 1.654 on d and 0.7052 on q across legal pairs.
- Dominant sensitivity within the declared plant-only grid: `Ld` (normalized span 2.063).

## 4. Unverified assumptions

- Fixed speed is imposed externally; no mechanical-speed loop, iron loss, magnetic saturation, thermal model, sensor quantization, or hardware delay uncertainty is claimed.
- Parameter sensitivity is not a temperature or saturation experiment. Stress cases are not a real operating envelope.

## 5. Strict P0 regression

- Gate: **PASS**. Case/vector/nonzero-duration match, current, U3 and aggregate thresholds were preregistered. See `results/summary/p0_regression_summary.csv`.

## 6. Six-condition results

- 11/12 rows are legal/stable. Mean P1 d/q RMSE: NaN/NaN A; maximum engineering violation rate: 0.

## 7. Two-axis alpha

- Cross-condition effective: **NO**. d improvement fraction 1.000; q worsening fraction 1.000; THD improvement fraction 0.600.

## 8. Negative id

- id scan: [-6 -4 -2 0] A. Mean relative THD change at most-negative id: -11.12%; torque-ripple change: 1.73%. Engineering degradation flag: **NO**.

- Failed negative-id rows: 2. Legal paired metrics do not override a failed high-speed legality gate.

## 9. Parameter sensitivity

- 60 plant-only one-at-a-time runs; controller parameters remained nominal. Most sensitive: `Ld`.

## 10. Stress test

- 27 labeled stress runs completed. They do not represent a real parameter range or real-world robustness claim.

## 11. F-estimator comparison

- Algebraic aggregate prediction error: 0.0161431 A; best online `algebraic_iter11`: 0.0161431 A; offline Oracle: 0.0126817 A (improvement 21.44%). ESO is a comparison baseline, not an innovation.

## 12. Residual root cause

- See `results/summary/residual_rootcause_summary.csv` and `diagnostics/residual_rootcause_evidence.md`. Transition and voltage results are associations only. The interval Oracle is definitionally noncausal and supplies a lower bound, not causal proof.

- Saliency amplifies the d-axis interval-F residual while reducing the q-axis residual; this axis-dependent result must not be collapsed into one favorable combined norm.

## 13. Numerical closure

- Gate: **PASS**. RK4 steps: [2 1 0.5 0.25] us; selected midpoint-vs-exact maximum 0.000392331 V and mean 0.0001252 V.

## 14. Engineering meaning

The result establishes a reproducible fixed-speed simulation baseline with explicit legality, actual-exceedance, estimator, and numerical gates. It does not establish hardware readiness.

## 15. Research meaning

Only the selected A-F decision is supported. Offline Oracle and basic ESO comparisons are diagnostic controls, not proposed novelty.

## 16. Stop conditions

A0 failure stops A1-A8; any core unit-test failure prevents a theoretical conclusion; illegal commands, negative dwell, long saturation, or unresolved numerical closure prohibit MTPA admission.

## 17. Final decision

**E. 当前移植不成立**

## 18. Single next recommendation

Close the failed or ambiguous evidence gate before any MTPA or controller redesign.
