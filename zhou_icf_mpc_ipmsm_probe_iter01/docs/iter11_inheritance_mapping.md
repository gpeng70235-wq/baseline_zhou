# Iteration 11 inheritance mapping

An initial mapping file was created before migration; this expanded audit reflects the final v1.1 implementation. Iteration 11 remained read-only. “Adapted” is used whenever namespace, interface, metadata, numerical policy, or motor equations changed; no MATLAB source file is claimed byte-identical.

| Iteration 11 file/module | IPMSM project file/module | treatment | reason |
|---|---|---|---|
| `src/+zhou/+controller/estimate_F.m` | `src/+zhou_ipmsm/+controller/estimate_ultralocal_F.m` | adapted | causal estimator formula retained; namespace/interface simplified |
| `predict_k1.m`, `predict_k2.m` | `predict_current.m` | adapted | common ultralocal Euler predictor reused for both horizons |
| `compute_V_terms.m`, `independent_costs.m`, `icf_mpc_step.m` | `controller/icf_mpc_step.m` | adapted | prediction/independent-cost flow retained; independent `Ld/Lq` alpha and local configuration added |
| `sequence_equivalent_dq_voltage.m` | same target name | adapted | exact segment-midpoint/delay formula retained; interface and strings adapted |
| `geometry/build_rectangle.m` | `geometry/build_voltage_rectangle.m` | adapted | rectangle equations retained with explicit axis vectors |
| `geometry/classify_case.m`, `point_in_rectangle.m` | `geometry/classify_case.m`, `validate_candidate_geometry.m` | adapted | origin/three-line Case decision retained and consolidated |
| `active_lines.m`, `line_rectangle_intersections.m` | `geometry/calculate_intersections.m` | adapted | three infinite AVV-line intersections retained in one reusable function |
| `select_savv.m`, `case2_midpoint.m`, `line_side_signature.m` | local Case-2 helpers in `controller/icf_mpc_step.m` | adapted | Table-I selection/phase flip retained; ambiguous Table-II algebra replaced by the paper-prose geometric midpoint |
| `modulation/case1_command.m`, `case2_command.m`, `case3_command.m` | `modulation/generate_case_sequence.m` | adapted | zero, SAVV+zero, and five-segment barycentric sequences consolidated; six-sector ordering retained |
| command duration checks in modulation/model | `calculate_durations.m`, `validate_durations.m`, sequence/integrator contracts | adapted | finite, nonnegative, sum-to-`Ts`, and vector-ID checks made explicit |
| `inverter/voltage_vectors.m` | `inverter/voltage_vectors.m`, `switching_state_to_alphabeta.m` | adapted | motor-independent two-level vectors retained; local state transform added |
| `inverter/count_sequence_transitions.m` | `inverter/count_switching_actions.m` | adapted | Hamming transition count retained; zero-duration states filtered by the caller |
| `math/park.m`, `math/inv_park.m` | `inverter/park.m` | adapted | required Park direction retained; unused inverse helper excluded |
| `model/pmsm_derivative.m` | `model/ipmsm_dq_dynamics.m` | adapted | SMPMSM `Ls` replaced by explicit `Ld/Lq` cross coupling |
| `model/electromagnetic_torque.m` | `calculate_ipmsm_torque.m`, `calculate_torque_components.m` | adapted | reluctance torque and component audit added |
| `model/integrate_command.m` | `integrate_ipmsm_sequence_rk4.m` | adapted | switching-segment RK4 retained; Park voltage evaluated at RK4 sub-times |
| `sim/run_closed_loop.m` | `src/+zhou_ipmsm/run_probe_case.m` | adapted | fixed-speed loop, one-step queue, and logs compacted for four IPMSM probes |
| `metrics/phase_thd*.m`, summary/constraint/case helpers | `metrics/calculate_*.m` | adapted | compact probe metrics with explicit selected/applied legality and Case counts |
| Iteration 11 I/O helpers | `src/+zhou_ipmsm/+io/*.m` | adapted/new | run isolation retained; summary schema evolution and binary-safe source manifest added |
| `config/paper_parameters.m`, assumptions, experiments | `config/*.m` | adapted | paper motor constants retained where applicable; IPMSM and probe assumptions isolated |
| `tests/unit/test_core_geometry_oracles.m` | nine named files under `tests/unit/` | adapted/new | inherited oracles expanded for IPMSM equations, frame queue, saliency, and nonzero `id` |
| `paper/source/zhou_2025_icf_mpc.pdf` | `reference/source_paper/zhou_2025_icf_mpc.pdf` | unchanged | only byte-identical copied artifact; SHA-256 `CDCE7966...87B04C` |
| algebraic `F` estimator, FCS baseline, dead-time model, waveform observer | — | excluded | outside the focused IPMSM migration probe |
| Iteration 11 `results/`, `plots/`, `diagnostics/`, `logs/`, caches, run IDs | — | excluded | generated legacy artifacts were prohibited from copying |
| `reference/constant_*`, explicit IPMSM parameters, negative-`id` sweep | corresponding target files | new | IPMSM-only functionality |

`reference/iter11_source_manifest.sha256` contains a 55-file config/src/tests subset of the Iteration 11 source snapshot. It is not a copy of generated results and is used only for provenance auditing; the running project never resolves or calls an Iteration 11 path.
