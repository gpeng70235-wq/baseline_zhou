# Changelog

## 1.1.0 — 2026-07-12

Post-implementation audit and executable acceptance release. Every source/document path changed in this release is registered below.

### Root and configuration

| file | change |
|---|---|
| `initialize_project.m` | reset default path; add only local code paths; reject sibling Zhou/Wu/audit paths; write PASS/FAIL audit; validate inputs |
| `run_ipmsm_probe.m` | unique run ID, strict gated order, downstream skip, diary/ledger, detailed final report, manifest-last order |
| `README.md` | complete purpose, structure, run/config/result entry points, and limits |
| `config/base_parameters.m` | v1.1 settings, 5 ms ramp, removed duplicated motor constants |
| `config/ipmsm_parameters.m` | authoritative motor constants and `Ld/Lq` assumptions |
| `config/experiment_definitions.m` | explicit P0/P1, alpha modes, and negative-`id` sweep |
| `config/acceptance_thresholds.m` | common safety/constraint/THD/RMSE and effect-size gates |
| `config/implementation_assumptions.m` | frame, integrator, inverter, estimator, and Case-2 policies |

### Reusable implementation

| file | change |
|---|---|
| `src/+zhou_ipmsm/run_probe_case.m` | one-period pending queue; applied/selected audits; ramped reference; Case/constraint/THD/torque/switching metrics |
| `src/+zhou_ipmsm/+controller/icf_mpc_step.m` | reconnected independent-constraint rectangle, Table-I Case 2, Case 1/2/3 sequence, axis-specific alpha, and frame timing |
| `src/+zhou_ipmsm/+controller/predict_current.m` | shared ultralocal predictor |
| `src/+zhou_ipmsm/+controller/estimate_ultralocal_F.m` | causal Iteration 11 estimator adaptation |
| `src/+zhou_ipmsm/+controller/sequence_equivalent_dq_voltage.m` | retained per-segment execution-midpoint transform |
| `src/+zhou_ipmsm/+controller/build_current_reference.m` | explicit two-axis reference path |
| `src/+zhou_ipmsm/+model/ipmsm_dq_dynamics.m` | explicit `Ld/Lq` plant equations |
| `src/+zhou_ipmsm/+model/integrate_ipmsm_sequence_rk4.m` | strict sequence contract and rotating-frame RK4 sub-times |
| `src/+zhou_ipmsm/+model/calculate_ipmsm_torque.m` | single-source total torque |
| `src/+zhou_ipmsm/+model/calculate_torque_components.m` | magnet/reluctance decomposition |
| `src/+zhou_ipmsm/+geometry/build_voltage_rectangle.m` | axis-specific independent-cost rectangle |
| `src/+zhou_ipmsm/+geometry/classify_case.m` | origin/three-active-line Case 1/2/3 decision |
| `src/+zhou_ipmsm/+geometry/calculate_intersections.m` | robust line/polygon intersections |
| `src/+zhou_ipmsm/+geometry/validate_candidate_geometry.m` | sequence and optional rectangle membership contract |
| `src/+zhou_ipmsm/+modulation/generate_case_sequence.m` | complete Case contract, Iteration 11 six-sector order, feasibility/saturation audit, nonnegative dwell normalization |
| `src/+zhou_ipmsm/+modulation/calculate_durations.m` | public duration accessor |
| `src/+zhou_ipmsm/+modulation/validate_durations.m` | duration sum/nonnegative validator |
| `src/+zhou_ipmsm/+inverter/voltage_vectors.m` | local two-level vector table |
| `src/+zhou_ipmsm/+inverter/switching_state_to_alphabeta.m` | state-to-voltage transform |
| `src/+zhou_ipmsm/+inverter/count_switching_actions.m` | transition counter (caller filters zero-duration segments) |
| `src/+zhou_ipmsm/+inverter/park.m` | local Park transform |
| `src/+zhou_ipmsm/+reference/constant_id_reference.m`, `constant_iq_reference.m` | IPMSM reference helpers |
| `src/+zhou_ipmsm/+metrics/calculate_tracking_metrics.m` | d/q RMSE |
| `src/+zhou_ipmsm/+metrics/calculate_constraint_metrics.m` | compact legality/duration helper |
| `src/+zhou_ipmsm/+metrics/calculate_switching_metrics.m` | total/per-step actions |
| `src/+zhou_ipmsm/+metrics/calculate_thd.m` | finite short-input guard and safe FFT-bin power calculation |

### I/O and experiments

| file | change |
|---|---|
| `src/+zhou_ipmsm/+io/create_run_directory.m` | non-overwriting result/plot/snapshot directories |
| `src/+zhou_ipmsm/+io/save_configuration_snapshot.m` | run configuration MAT snapshot |
| `src/+zhou_ipmsm/+io/write_result_table.m` | append-preserving summary schema evolution |
| `src/+zhou_ipmsm/+io/generate_source_manifest.m` | sorted, binary-safe SHA-256; excludes generated outputs |
| `src/+zhou_ipmsm/+io/append_summary_rows.m` | correct per-condition required metadata |
| `src/+zhou_ipmsm/+io/export_trace_plot.m` | reusable trace/torque/Case figure |
| `src/+zhou_ipmsm/+io/save_experiment_result.m` | common single-experiment persistence |
| `experiments/experiment_P0_degenerate_regression.m` | analytical SMPMSM derivative/torque oracle and target contract |
| `experiments/experiment_P1_saliency_probe.m` | paired observed saliency effect |
| `experiments/experiment_alpha_mode_comparison.m` | two-condition metrics, summaries, and comparison plot |
| `experiments/experiment_negative_id_sweep.m` | four-condition metrics, summaries, and reluctance-torque plot |

### Tests, documentation, and provenance

| file | change |
|---|---|
| `tests/run_unit_tests.m` | named-suite presence checks, empty-suite rejection, and per-test diagnostics |
| `tests/unit/test_project_isolation.m` | workspace/path/function-resolution isolation |
| `tests/unit/test_ipmsm_reduces_to_smpmsm.m` | derivative and zero-reluctance oracle |
| `tests/unit/test_ipmsm_dq_equation_signs.m` | explicit equation oracle/sign checks |
| `tests/unit/test_ipmsm_torque_equation.m` | independent closed-form component oracle with scaled tolerance |
| `tests/unit/test_alpha_d_alpha_q_usage.m` | controller output verifies independent/common alpha modes |
| `tests/unit/test_frame_angle_patch_preserved.m` | analytical segment oracle, queue delays, and geometry angle |
| `tests/unit/test_nonzero_id_reference_path.m` | negative-`id` closed-loop and positive reluctance torque |
| `tests/unit/test_no_negative_duration_ipmsm.m` | all Cases and all six sector sequence orders |
| `tests/unit/test_no_illegal_command_ipmsm.m` | Case classification, saturation detection, full controller safety smoke |
| `docs/project_structure.md`, `migration_plan.md`, `model_equation_mapping.md` | architecture, migration, and equations expanded |
| `docs/iter11_inheritance_mapping.md` | corrected per-module adapted/new/excluded mapping |
| `docs/parameter_sources.md`, `assumptions_and_limitations.md`, `test_and_acceptance_plan.md` | sources, assumptions, and executable gates documented |
| `diagnostics/migration_code_audit.md`, `frame_patch_inheritance_audit.md`, `regression_failure_diagnosis.md` | hash evidence, timing proof, and development failures recorded |
| `reference/iter11_regression_targets.csv` | nonempty analytical/invariant target contract |
| `reference/iter11_source_manifest.sha256`, `reference/source_paper/zhou_2025_icf_mpc.pdf` | read-only source/PDF provenance retained |
| `FINAL_IPMSM_PROBE_REPORT.md`, `SOURCE_MANIFEST.sha256`, `diagnostics/path_isolation_audit.md`, `logs/*`, `results/*`, `plots/*` | generated/refreshed only by initialization or the formal runner |

## 1.0.0 — 2026-07-12

- Created the isolated project skeleton and initial Iteration 11 migration mapping.
- Added the first IPMSM plant, controller, four gated experiments, run-ID layout, documentation, and nine required test files.
- Excluded all Iteration 11 generated results, plots, diagnostics, logs, caches, and run IDs.
