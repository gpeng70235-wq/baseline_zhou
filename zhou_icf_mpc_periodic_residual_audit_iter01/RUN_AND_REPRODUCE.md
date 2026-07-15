# Run and Reproduce

Environment: MATLAB R2024b with Signal Processing Toolbox; deterministic seed `20260715`.

```matlab
cd('C:/Users/catkin/Documents/baseline_zhou/zhou_icf_mpc_periodic_residual_audit_iter01');
outcome = run_periodic_residual_audit('all');
```

The first phase verifies/copies frozen data and hashes upstreams. The B0 gate must pass before analysis. `all` regenerates every registered CSV, 16 figures, formal decision, handoff, and AFTER hashes.
No sibling is added to MATLAB path. To test a stage, replace `all` with any supported mode; each mode deterministically executes its prerequisites.
Expected final code is read from `results/summary/final_decision.csv`; never infer success from a figure alone.
