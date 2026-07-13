function a = implementation_assumptions()
%IMPLEMENTATION_ASSUMPTIONS Settings not uniquely specified by the paper.
% Every field in this file is an implementation assumption, not a paper value.
% See docs/ambiguities.md for rationale and possible alternatives.

a.label = "IMPLEMENTATION ASSUMPTIONS - NOT PAPER PARAMETERS";
a.dc_bus_V = 84;
a.dc_bus_identification_source_run = "Iteration06/20260712_013853_794_vdc_identification";
a.vdc_identification_candidates_V = [36,48,60,72,84];
a.vdc_identification_Cf_weight = 0.5;
a.vdc_identification_favg_weight = 0.5;
a.voltage_vector_scale = 2/3; % amplitude-invariant space-vector convention
a.voltage_tolerance_V = 1e-10;
a.line_distance_tolerance_V = 1e-10;
a.sector_angle_tolerance_rad = 1e-12;
a.duty_tolerance = 1e-12;
a.geometry_tolerance = a.voltage_tolerance_V; % compatibility alias
a.constraint_tolerance_A2 = 1e-9;
a.constraint_tolerance = a.constraint_tolerance_A2; % compatibility alias
a.time_tolerance_s = 1e-13;
a.random_seed = 20250711;
a.audit_residual_multiplier = 1000;
a.experiment_A_random_samples = 96;
a.experiment_A_forced_centers_ab_V = [0.4,-0.2; 10,0; 8,6];
a.experiment_A_forced_halfwidths_dq_V = [2,1.5; 2,0.8; 0.35,0.30];
a.experiment_A_forced_theta_rad = 0.37;
a.experiment_A_random_radius_V = [0.5, 18.0];
a.experiment_A_random_halfwidth_V = [0.05, 5.0];
a.experiment_A_degenerate_center_ab_V = [1,1];
a.experiment_A_degenerate_halfwidth_dq_V = [0.75,0];
a.experiment_A_degenerate_theta_rad = 0;
a.experiment_A_phase_counterexample_center_ab_V = [2.8811425114,2.0410806401];
a.experiment_A_phase_counterexample_halfwidth_dq_V = [4.7413011531,0.3201848959];
a.experiment_A_phase_counterexample_theta_rad = 0.7223486583;
a.table_I_mode = "minimal_geometry_consistent_correction";
a.table_I_infeasible_phase_policy = "opposite_vector_on_same_AVV_line_with_audit";
a.degenerate_intersection_policy = "single_point_is_its_own_midpoint";
a.case1_boundary_is_inside = true;
a.unreachable_voltage_policy = "audit_failure_no_silent_projection";
a.estimator = "fliess_join_2013_algebraic_integral";
a.estimator_window_samples = 5;
a.estimator_quadrature = "exact_piecewise_linear_y_zero_order_hold_u";
a.estimator_initial_F_dq = [0, 0];
a.preinitialize_fixed_speed_controller = true;
a.speed_source = "ideal_external_constant_speed";
a.load_torque_Nm = 0;
a.current_reference_ramp_s = 0.02;
a.phase_current_thd_max_harmonic = 40; % retained only for the legacy boundary-sample audit
a.waveform_sample_period_s = 2e-6;
a.waveform_metric_method = "dense_switch_sequence_total_rms_residual_primary_THD";
a.primary_THD_definition = "full_resolved_bandwidth_RMS_after_DC_and_fundamental_removal";
a.waveform_endpoint_tolerance_A = 1e-3;
a.inverter_disturbance_model = "paper_2us_average_deadtime_per_commutated_leg";
a.deadtime_current_zero_tolerance_A = 1e-9;
a.exec_time_exclude_fraction = 0.10;
a.plot_visible = "off";
a.candidate_voltage_frame_mode = "execution_segment_midpoint";
end
