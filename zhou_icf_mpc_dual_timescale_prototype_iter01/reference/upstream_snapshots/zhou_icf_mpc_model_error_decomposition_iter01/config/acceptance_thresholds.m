function t=acceptance_thresholds()
%ACCEPTANCE_THRESHOLDS Frozen P0 gates plus campaign engineering gates.
t.p0_duration_max_abs_s=1e-9;t.p0_current_max_abs_A=1e-6;
t.p0_U3_max_abs_V=1e-6;t.p0_summary_relative=1e-3;t.numeric_tolerance=1e-12;
t.engineering_relative_change=0.10;
t.max_predicted_constraint_failure_rate=0;
t.max_negative_duration_count=0;
t.deterministic_test_axis_coverage_min=0.999;
t.conformal_target_coverage=0.995;
t.max_serious_miss_consecutive_cycles=1;
t.C2_violation_reduction_fraction=0.80;
t.C2_absolute_violation_rate=0.005;
t.max_THD_relative_degradation=0.10;
t.max_torque_ripple_relative_degradation=0.10;
t.max_switching_relative_increase=0.10;
t.max_long_term_S3_fraction=0.05;
end
