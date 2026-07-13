# Numerical closure audit

- run_id: `20260713_084757_ipmsm_validation`
- gate: **PASS**

`U3_internal` and `U4_internal` compare logged values with an independent reconstruction of the same segment-midpoint convention. `midpoint_vs_exact` is the gated selected-sequence midpoint U3 versus exact rotating-frame U4 error; the exact value is offline and is not substituted into the controller.

| RK4 max step (s) | endpoint error to finest (A) |
|---:|---:|
| 2e-06 | 3.66914778e-12 |
| 1e-06 | 3.60571603e-12 |
| 5e-07 | 7.73833712e-12 |
| 2.5e-07 | 0 |
