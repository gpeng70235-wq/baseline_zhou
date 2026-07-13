# Baseline inheritance mapping

Iteration 11 is treated as a fixed validation source snapshot, not as an authority freeze. The snapshot below is never added to the MATLAB path.

| source file | new project file | class | reason |
|---|---|---|---|
| `reference/iter11/source_snapshot/+zhou/+baseline/fcs_mpcc_step.m` | `src/+zhou_iter11_ref/+baseline/fcs_mpcc_step.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+baseline/fcs_mpcc_step.m` | `src/+zhou_ipmsm/+baseline/fcs_mpcc_step.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+controller/compute_V_terms.m` | `src/+zhou_iter11_ref/+controller/compute_V_terms.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+controller/compute_V_terms.m` | `src/+zhou_ipmsm/+controller/compute_V_terms.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+controller/costs_from_voltage.m` | `src/+zhou_iter11_ref/+controller/costs_from_voltage.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+controller/costs_from_voltage.m` | `src/+zhou_ipmsm/+controller/costs_from_voltage.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+controller/estimate_F.m` | `src/+zhou_iter11_ref/+controller/estimate_F.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+controller/estimate_F.m` | `src/+zhou_ipmsm/+controller/estimate_F.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+controller/estimate_F_algebraic.m` | `src/+zhou_iter11_ref/+controller/estimate_F_algebraic.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+controller/estimate_F_algebraic.m` | `src/+zhou_ipmsm/+controller/estimate_F_algebraic.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+controller/icf_mpc_step.m` | `src/+zhou_iter11_ref/+controller/icf_mpc_step.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+controller/icf_mpc_step.m` | `src/+zhou_ipmsm/+controller/icf_mpc_step.m` | adapted | F override hook for comparison only; default algebraic path frozen |
| `reference/iter11/source_snapshot/+zhou/+controller/independent_costs.m` | `src/+zhou_iter11_ref/+controller/independent_costs.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+controller/independent_costs.m` | `src/+zhou_ipmsm/+controller/independent_costs.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+controller/predict_k1.m` | `src/+zhou_iter11_ref/+controller/predict_k1.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+controller/predict_k1.m` | `src/+zhou_ipmsm/+controller/predict_k1.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+controller/predict_k2.m` | `src/+zhou_iter11_ref/+controller/predict_k2.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+controller/predict_k2.m` | `src/+zhou_ipmsm/+controller/predict_k2.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+controller/sequence_equivalent_dq_voltage.m` | `src/+zhou_iter11_ref/+controller/sequence_equivalent_dq_voltage.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+controller/sequence_equivalent_dq_voltage.m` | `src/+zhou_ipmsm/+controller/sequence_equivalent_dq_voltage.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+geometry/active_lines.m` | `src/+zhou_iter11_ref/+geometry/active_lines.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+geometry/active_lines.m` | `src/+zhou_ipmsm/+geometry/active_lines.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+geometry/analyze_rectangle.m` | `src/+zhou_iter11_ref/+geometry/analyze_rectangle.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+geometry/analyze_rectangle.m` | `src/+zhou_ipmsm/+geometry/analyze_rectangle.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+geometry/build_rectangle.m` | `src/+zhou_iter11_ref/+geometry/build_rectangle.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+geometry/build_rectangle.m` | `src/+zhou_ipmsm/+geometry/build_rectangle.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+geometry/case2_midpoint.m` | `src/+zhou_iter11_ref/+geometry/case2_midpoint.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+geometry/case2_midpoint.m` | `src/+zhou_ipmsm/+geometry/case2_midpoint.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+geometry/classify_case.m` | `src/+zhou_iter11_ref/+geometry/classify_case.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+geometry/classify_case.m` | `src/+zhou_ipmsm/+geometry/classify_case.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+geometry/line_rectangle_intersections.m` | `src/+zhou_iter11_ref/+geometry/line_rectangle_intersections.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+geometry/line_rectangle_intersections.m` | `src/+zhou_ipmsm/+geometry/line_rectangle_intersections.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+geometry/line_side_signature.m` | `src/+zhou_iter11_ref/+geometry/line_side_signature.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+geometry/line_side_signature.m` | `src/+zhou_ipmsm/+geometry/line_side_signature.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+geometry/point_in_rectangle.m` | `src/+zhou_iter11_ref/+geometry/point_in_rectangle.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+geometry/point_in_rectangle.m` | `src/+zhou_ipmsm/+geometry/point_in_rectangle.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+geometry/sector_of_point.m` | `src/+zhou_iter11_ref/+geometry/sector_of_point.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+geometry/sector_of_point.m` | `src/+zhou_ipmsm/+geometry/sector_of_point.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+geometry/select_savv.m` | `src/+zhou_iter11_ref/+geometry/select_savv.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+geometry/select_savv.m` | `src/+zhou_ipmsm/+geometry/select_savv.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+inverter/count_sequence_transitions.m` | `src/+zhou_iter11_ref/+inverter/count_sequence_transitions.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+inverter/count_sequence_transitions.m` | `src/+zhou_ipmsm/+inverter/count_sequence_transitions.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+inverter/deadtime_voltage_error.m` | `src/+zhou_iter11_ref/+inverter/deadtime_voltage_error.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+inverter/deadtime_voltage_error.m` | `src/+zhou_ipmsm/+inverter/deadtime_voltage_error.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+inverter/voltage_vectors.m` | `src/+zhou_iter11_ref/+inverter/voltage_vectors.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+inverter/voltage_vectors.m` | `src/+zhou_ipmsm/+inverter/voltage_vectors.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+io/append_standard_tables.m` | `src/+zhou_iter11_ref/+io/append_standard_tables.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+io/append_standard_tables.m` | `src/+zhou_ipmsm/+io/append_standard_tables.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+io/append_text.m` | `src/+zhou_iter11_ref/+io/append_text.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+io/append_text.m` | `src/+zhou_ipmsm/+io/append_text.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+io/create_run_context.m` | `src/+zhou_iter11_ref/+io/create_run_context.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+io/create_run_context.m` | `src/+zhou_ipmsm/+io/create_run_context.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+io/file_sha256.m` | `src/+zhou_iter11_ref/+io/file_sha256.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+io/file_sha256.m` | `src/+zhou_ipmsm/+io/file_sha256.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+io/write_code_manifest.m` | `src/+zhou_iter11_ref/+io/write_code_manifest.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+io/write_code_manifest.m` | `src/+zhou_ipmsm/+io/write_code_manifest.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+io/write_or_append_table.m` | `src/+zhou_iter11_ref/+io/write_or_append_table.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+io/write_or_append_table.m` | `src/+zhou_ipmsm/+io/write_or_append_table.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+io/write_text_new.m` | `src/+zhou_iter11_ref/+io/write_text_new.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+io/write_text_new.m` | `src/+zhou_ipmsm/+io/write_text_new.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+math/inv_park.m` | `src/+zhou_iter11_ref/+math/inv_park.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+math/inv_park.m` | `src/+zhou_ipmsm/+math/inv_park.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+math/park.m` | `src/+zhou_iter11_ref/+math/park.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+math/park.m` | `src/+zhou_ipmsm/+math/park.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+metrics/case_statistics_table.m` | `src/+zhou_iter11_ref/+metrics/case_statistics_table.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+metrics/case_statistics_table.m` | `src/+zhou_ipmsm/+metrics/case_statistics_table.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+metrics/constraint_violations_table.m` | `src/+zhou_iter11_ref/+metrics/constraint_violations_table.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+metrics/constraint_violations_table.m` | `src/+zhou_ipmsm/+metrics/constraint_violations_table.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+metrics/phase_thd.m` | `src/+zhou_iter11_ref/+metrics/phase_thd.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+metrics/phase_thd.m` | `src/+zhou_ipmsm/+metrics/phase_thd.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+metrics/phase_thd_total_rms.m` | `src/+zhou_iter11_ref/+metrics/phase_thd_total_rms.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+metrics/phase_thd_total_rms.m` | `src/+zhou_ipmsm/+metrics/phase_thd_total_rms.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+metrics/summarize_simulation.m` | `src/+zhou_iter11_ref/+metrics/summarize_simulation.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+metrics/summarize_simulation.m` | `src/+zhou_ipmsm/+metrics/summarize_simulation.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+metrics/summary_to_long_table.m` | `src/+zhou_iter11_ref/+metrics/summary_to_long_table.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+metrics/summary_to_long_table.m` | `src/+zhou_ipmsm/+metrics/summary_to_long_table.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+model/electromagnetic_torque.m` | `src/+zhou_iter11_ref/+model/electromagnetic_torque.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+model/electromagnetic_torque.m` | `src/+zhou_ipmsm/+model/electromagnetic_torque.m` | adapted | adapted to PM plus reluctance torque |
| `reference/iter11/source_snapshot/+zhou/+model/integrate_command.m` | `src/+zhou_iter11_ref/+model/integrate_command.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+model/integrate_command.m` | `src/+zhou_ipmsm/+model/integrate_command.m` | adapted | adapted with configurable RK4 substep; dwell boundaries unchanged |
| `reference/iter11/source_snapshot/+zhou/+model/phase_currents.m` | `src/+zhou_iter11_ref/+model/phase_currents.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+model/phase_currents.m` | `src/+zhou_ipmsm/+model/phase_currents.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+model/pmsm_derivative.m` | `src/+zhou_iter11_ref/+model/pmsm_derivative.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+model/pmsm_derivative.m` | `src/+zhou_ipmsm/+model/pmsm_derivative.m` | adapted | adapted to explicit Ld/Lq IPMSM equations with exact P0 branch |
| `reference/iter11/source_snapshot/+zhou/+model/sample_command_waveform.m` | `src/+zhou_iter11_ref/+model/sample_command_waveform.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+model/sample_command_waveform.m` | `src/+zhou_ipmsm/+model/sample_command_waveform.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+modulation/case1_command.m` | `src/+zhou_iter11_ref/+modulation/case1_command.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+modulation/case1_command.m` | `src/+zhou_ipmsm/+modulation/case1_command.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+modulation/case2_command.m` | `src/+zhou_iter11_ref/+modulation/case2_command.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+modulation/case2_command.m` | `src/+zhou_ipmsm/+modulation/case2_command.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+modulation/case3_command.m` | `src/+zhou_iter11_ref/+modulation/case3_command.m` | adapted | package namespace adapted; controller math frozen |
| `reference/iter11/source_snapshot/+zhou/+modulation/case3_command.m` | `src/+zhou_ipmsm/+modulation/case3_command.m` | adapted | namespace adapted; inherited Case/frame/duration/vector logic |
| `reference/iter11/source_snapshot/+zhou/+sim/run_closed_loop.m` | `src/+zhou_iter11_ref/+sim/run_closed_loop.m` | adapted | namespace adapted; read-only trace instrumentation added |
| `reference/iter11/source_snapshot/+zhou/+sim/run_closed_loop.m` | `src/+zhou_ipmsm/+sim/run_closed_loop.m` | adapted | adapted plant/alpha/estimator state and audit logging; controller geometry frozen |
| `external_iter11/config/paper_parameters.m` | `reference/iter11/config_snapshot/paper_parameters.m` | unchanged | byte-for-byte frozen source |
| `external_iter11/config/implementation_assumptions.m` | `reference/iter11/config_snapshot/implementation_assumptions.m` | unchanged | byte-for-byte frozen source |
| `external_iter11/config/experiment_definitions.m` | `reference/iter11/config_snapshot/experiment_definitions.m` | unchanged | byte-for-byte frozen source |
| `external_iter11/config/frame_alignment_config.m` | `reference/iter11/config_snapshot/frame_alignment_config.m` | unchanged | byte-for-byte frozen source; not trusted as an active old entry |
| `external_probe/model/ipmsm_dq_dynamics.m` | `src/+zhou_ipmsm/+model/pmsm_derivative.m` | adapted | equation reference only; Iteration 11 queue/core retained |
| `external_residual_audit/F_oracle_comparison.csv` | `reference/frozen_targets/F_oracle_comparison.csv` | unchanged | read-only evidence; never read by runtime |
| `old results/plots/logs/run_id` | `none` | excluded | runtime dependency prohibited |
