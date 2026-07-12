# Zhou ICF-MPC IPMSM probe iter01

This is an independent MATLAB project for probing the Iteration 11 ICF-MPC path on an interior PMSM. It retains the independent-constraint rectangle, Case 1/2/3 selection, symmetric multi-vector dwell sequences, causal ultralocal `F` estimate, and execution-segment midpoint frame correction. The plant, torque, controller gains, and references explicitly support `Ld ~= Lq` and nonzero `id`.

The project does not add Iteration 10, Iteration 11, any Wu project, or any audit project to the MATLAB path. Historical results, plots, diagnostics, logs, caches, and run IDs were not copied.

## One-command run

```matlab
cd('C:/Users/catkin/Documents/baseline_zhou/zhou_icf_mpc_ipmsm_probe_iter01');
run_ipmsm_probe
```

The fixed gate order is unit tests → P0 analytical SMPMSM degeneracy → P1 saliency → alpha-mode comparison → negative-`id` sweep. A failed gate skips every later experiment.

## Directory and configuration entry points

- `config/`: base parameters, IPMSM parameters, experiment matrix, thresholds, and assumptions.
- `src/+zhou_ipmsm/`: reusable controller, plant, geometry, modulation, inverter, metrics, references, and I/O.
- `experiments/`: exactly four independent experiment entry functions.
- `tests/`: automated unit/functional tests; tests never create formal paper results.
- `docs/` and `reference/`: design records and read-only source provenance.
- `results/<experiment>/<run_id>/`: CSV/MAT results and `config_snapshot/`.
- `plots/<experiment>/<run_id>/`: PNG figures only.
- `diagnostics/` and `logs/`: audits, errors, test logs, execution log, and run ledger.

Edit `config/base_parameters.m`, `config/ipmsm_parameters.m`, and `config/experiment_definitions.m` to configure a run. Acceptance limits are centralized in `config/acceptance_thresholds.m`.

## Review entry points

Start with:

1. `FINAL_IPMSM_PROBE_REPORT.md`
2. `results/summary/regression_summary.csv`
3. `results/summary/ipmsm_probe_summary.csv`
4. `CHANGELOG_IPMSM.md`

The alpha comparison and negative-`id` sweep also have dedicated summary CSVs in `results/summary/`.

## Current limits

Simulation only; ideal two-level inverter; fixed speed; no magnetic saturation, iron loss, dead time, mechanical transient, or online parameter drift. `Ld`, `Lq`, `Vdc`, and the reference ramp are declared engineering probe assumptions rather than parameters reported by Zhou et al. The work establishes an executable software migration path, not experimental IPMSM validation.
