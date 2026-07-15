function a=implementation_assumptions()
%IMPLEMENTATION_ASSUMPTIONS Frozen semantics plus explicit strategy labels.
a.dc_bus_V=48;a.voltage_vector_scale=2/3;
a.voltage_tolerance_V=1e-10;a.line_distance_tolerance_V=1e-10;
a.sector_angle_tolerance_rad=1e-12;a.duty_tolerance=1e-12;
a.geometry_tolerance=a.voltage_tolerance_V;a.constraint_tolerance_A2=1e-9;
a.constraint_tolerance=a.constraint_tolerance_A2;a.time_tolerance_s=1e-13;
a.random_seed=20250711;a.table_I_mode="minimal_geometry_consistent_correction";
a.table_I_infeasible_phase_policy="opposite_vector_on_same_AVV_line_with_audit";
a.degenerate_intersection_policy="single_point_is_its_own_midpoint";
a.case1_boundary_is_inside=true;
a.unreachable_voltage_policy="explicit_strategy_layer_no_silent_projection";
a.estimator="fliess_join_2013_algebraic_integral";a.estimator_window_samples=5;
a.estimator_quadrature="exact_piecewise_linear_y_zero_order_hold_u";
a.estimator_initial_F_dq=[0 0];a.preinitialize_fixed_speed_controller=true;
a.speed_source="ideal_external_constant_speed";a.load_torque_Nm=0;
a.current_reference_ramp_s=5e-3;a.phase_current_thd_max_harmonic=40;
a.waveform_sample_period_s=2e-6;a.waveform_metric_method="control-cycle samples";
a.primary_THD_definition="RMS of nonfundamental bins / fundamental RMS";
a.waveform_endpoint_tolerance_A=1e-3;
a.inverter_disturbance_model="none";a.deadtime_current_zero_tolerance_A=1e-9;
a.plot_visible="off";a.candidate_voltage_frame_mode="execution_segment_midpoint";
a.validation_run=true;a.oracle_online_allowed=false;
a.illegal_command_semantics="selected pending and applied logged independently";
a.fallback_weights_dq=[1 1];
a.exec_time_exclude_fraction=0.10;
a.residual_alignment_samples=2;
a.scheduled_bound_feature_names=["abs_omega_e_rad_s","abs_id_A","abs_iq_A", ...
    "voltage_utilization","sector_transition","case_transition", ...
    "command_transition","reference_ramp_rate_A_s"];
a.bound_fit_source="calibration_only";
a.conformal_target_coverage=0.995;
a.oracle_online_allowed=false;
end
