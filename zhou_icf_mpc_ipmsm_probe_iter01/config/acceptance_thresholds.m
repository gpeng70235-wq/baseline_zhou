function thresholds = acceptance_thresholds()
%ACCEPTANCE_THRESHOLDS Explicit gates used by all four experiments.
thresholds.reduction = 1e-10;
thresholds.equation = 1e-10;
thresholds.duration = 1e-12;
thresholds.max_rmse_A = 5;
thresholds.max_illegal = 0;
thresholds.max_constraint_violations = 0;
thresholds.max_geometry_outside = 0;
thresholds.max_saturated_commands = 0;
thresholds.max_phase_a_thd = 0.20;
thresholds.min_saliency_effect = 1e-3;
thresholds.min_alpha_mode_metric_delta = 1e-3;
thresholds.min_negative_id_reluctance_gain_Nm = 1e-3;
end
