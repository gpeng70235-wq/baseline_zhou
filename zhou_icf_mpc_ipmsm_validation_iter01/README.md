# Zhou ICF-MPC IPMSM validation iter01

## Purpose

A fully independent, reproducible validation baseline for Zhou ICF-MPC on an IPMSM.

## Research boundary

This project validates inheritance, saliency, negative id, plant-only mismatch, estimator controls and numerical closure. It does not add MTPA or propose a new controller.

## Current conclusion

**E. 当前移植不成立** — 严格P0已通过，但六工况合法性门因高速IPMSM非法Case失败。

## Structure

`config/`, `src/`, `estimators/`, `experiments/`, `tests/`, `reference/`, `docs/`, `results/`, `plots/`, `diagnostics/`, `logs/`, `delivery/`.

## MATLAB

Validated with MATLAB R2024b (`24.2.0.2712019 (R2024b)`).

## One-command run

```matlab
cd('C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_validation_iter01')
run_all_ipmsm_validation
```

## Quick test

```matlab
p=initialize_project("quick_test"); [pass,results]=run_unit_tests(p);
```

## Experiment matrix

A0 strict P0; A1 six-condition P0/P1; A2 alpha modes; A3 negative id; A4 sensitivity; A5 stress; A6 estimators; A7 residual cause; A8 numerical closure.

## Results

Formal run `20260713_084757_ipmsm_validation`; open `results/summary/` and `plots/summary/20260713_084757_ipmsm_validation/`.

## Handoff

Start with `IPMSM_VALIDATION_HANDOFF.md`.

## GitHub branch

`ipmsm-validation-iter01` (or its timestamped collision-safe successor).

## Known limits

Fixed-speed idealized simulation; see `docs/parameter_scope_and_limits.md`.

## Claims not supported

No hardware validation, temperature/saturation robustness, online Oracle, ESO novelty, or MTPA result is claimed.

## Continued-development rules

Do not modify the frozen Case/duration/frame/vector/constraint/F-baseline contracts in this iter01. Fork a new iteration for controller changes.
