# Design Spec Compliance Matrix

| Requirement | File | Function | Line | Complete | Deviation / impact |
|---|---|---|---:|---:|---|
| causal derivative and historical u_app | `src/+prototype/estimator_step.m` | `estimator_step` | 1 | true | none |
| post-S2 segment reconstruction | `src/+prototype/s2_input_quality_gate.m` | `s2_input_quality_gate` | 1 | true | none |
| 20-row projected alpha | `src/+prototype/alpha_update.m` | `alpha_update` | 1 | true | none |
| posterior-alpha fast F | `src/+prototype/F_update.m` | `F_update` | 1 | true | none |
| one-row latched trend | `src/+prototype/F_update.m` | `F_update` | 15 | true | one indexing defect found and fixed before final gate |
| two exact Ts predictions | `src/+prototype/dual_timescale_predictor.m` | `dual_timescale_predictor` | 1 | true | none |
| unchanged Zhou geometry and S2 | `src/+prototype/icf_mpc_step.m` | `icf_mpc_step` | 1 | true | copied packages SHA-equal |
| decision margin and native gap | `src/+prototype/decision_margin_gate.m` | `decision_margin_gate` | 1 | false | upstream exposes no runner-up mode cost; abs(Jd-Jq) adapter logged |
| constrained two-parameter RLS | `src/+prototype/constrained_rls_update.m` | `constrained_rls_update` | 1 | true | comparison only |
| hard gate order | `run_dual_timescale_prototype.m` | `run_dual_timescale_prototype` | 1 | true | later phases skipped |
