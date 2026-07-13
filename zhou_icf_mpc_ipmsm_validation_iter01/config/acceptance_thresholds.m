function t = acceptance_thresholds()
%ACCEPTANCE_THRESHOLDS Pre-registered gates; never relaxed after a run.

t.p0_case_match = 1;
t.p0_vector_match = 1;
t.p0_duration_structure_match = 1;
t.p0_duration_max_abs_s = 1e-9;
t.p0_current_max_abs_A = 1e-6;
t.p0_U3_max_abs_V = 1e-6;
t.p0_summary_relative = 1e-3;
t.max_illegal_commands = 0;
t.max_negative_durations = 0;
t.U3_U4_max_error_V = 1e-3;
t.U3_U4_mean_error_V = 2e-4;
t.max_engineering_violation_rate = 0.05;
t.long_saturation_rate = 0.20;
t.cross_condition_improvement_fraction = 2/3;
t.significant_metric_relative_change = 0.10;
t.significant_oracle_improvement = 0.20;
t.numeric_tolerance = 1e-12;
end
