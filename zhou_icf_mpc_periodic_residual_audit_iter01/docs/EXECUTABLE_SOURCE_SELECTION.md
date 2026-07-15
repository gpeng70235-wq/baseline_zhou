# Executable Source Selection

The audit consumes no live sibling code. It freezes selected evidence and data into `reference/` before analysis.

## Resolution

- **model_error**: requested `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_model_error_decomposition_iter01`; resolved `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_dual_timescale_prototype_iter01\reference\upstream_snapshots\zhou_icf_mpc_model_error_decomposition_iter01`; top-level stub; complete Git-frozen snapshot restored in prototype.
- **dual_design**: requested `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_dual_timescale_design_iter01`; resolved `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_dual_timescale_design_iter01`; direct non-empty project.
- **dual_prototype**: requested `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_dual_timescale_prototype_iter01`; resolved `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_dual_timescale_prototype_iter01`; direct non-empty project.
- **ipmsm_probe**: requested `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_probe_iter01`; resolved `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_probe_iter01`; direct non-empty project.
- **s2_feasibility**: requested `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_feasibility_control_iter01`; resolved `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_dual_timescale_prototype_iter01\reference\upstream_snapshots\zhou_icf_mpc_model_error_decomposition_iter01\reference\upstream_snapshots\s2_feasibility`; top-level stub; frozen evidence plus executable +zhou_feasibility in model-error snapshot.
- **sequence_decomposition**: requested `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_sequence_decomposition_iter01`; resolved `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_dual_timescale_prototype_iter01\reference\upstream_snapshots\zhou_icf_mpc_model_error_decomposition_iter01\reference\upstream_snapshots\sequence_decomposition`; top-level stub; frozen evidence plus executable +zhou_sequence in model-error snapshot.
- **jd_jq_audit**: requested `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_constraint_audit_v1`; resolved `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_dual_timescale_prototype_iter01\reference\upstream_snapshots\zhou_icf_mpc_model_error_decomposition_iter01\reference\upstream_snapshots\jd_jq_audit`; requested and nested paths are stubs; resolved to model-error frozen jd_jq evidence snapshot.

Empty or missing requested paths were not treated as source code: `model_error`, `s2_feasibility`, `sequence_decomposition`, `jd_jq_audit`.

## Selected executable/timing evidence

- The complete model-error snapshot restored at Git commit `2aa4e7f` supplies the 24-case aligned P0 data and timing implementation.
- `decompose_simulation.m` and `TIMING_ALIGNMENT_AUDIT.md` freeze the original `k -> k+2` semantics.
- The prototype B0 export supplies an independently reproduced overlap check for five cases.
- No controller, plant, S2, Jd/Jq limit, or dual-timescale estimator is copied as modifiable runtime.

## Frozen-copy gate

Copied files: **16**; byte-identical SHA-256 checks: **16/16**.
