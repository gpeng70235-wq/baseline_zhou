# Zhou ICF-MPC constraint audit v1

Independent, provenance-checked audit of fixed `Jd_limit` and `Jq_limit` across operating conditions. The frozen controller and plant copies under `src/+zhou_ipmsm` are not modified by the audit.

## Entry modes

```matlab
cd('C:/Users/catkin/Documents/baseline_zhou/baseline_zhou-main/baseline_zhou-main/zhou_icf_mpc_constraint_audit_v1')
run_constraint_audit()          % complete flow; identical to 'all'
run_constraint_audit('phase1')  % baseline/SHA validation only
run_constraint_audit('coarse')  % coarse grid, retain continuation marker
run_constraint_audit('focused') % ensure coarse checkpoints, refine, conclude
run_constraint_audit('all')     % baseline check -> coarse -> focused -> final report
```

A passed Phase 1 is reused only when the frozen source, previous problem audit, and copied dependencies retain exact SHA256 identity. Completed scan cases are loaded from per-case checkpoints and are not overwritten.

The coarse grid is constructed from current-error amplitudes and then squared. Automatic refinement covers the default neighborhood and multiple Pareto regions, not a single weighted optimum. Final results are written under `results/summary`, plots under `plots/summary/<run-id>`, and the formal A-E conclusion under `docs/CONSTRAINT_PROBLEM_EXISTENCE_REPORT.md`.
