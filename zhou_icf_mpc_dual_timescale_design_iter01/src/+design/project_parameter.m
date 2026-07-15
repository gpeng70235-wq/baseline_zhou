function out = project_parameter(action)
%PROJECT_PARAMETER Frozen, motor-parameter-free design constants.
% No actual Ld/Lq value is used. Alpha initialization comes from the
% frozen Zhou controller configuration; bounds are commissioning envelopes.

if nargin == 0
    action = "config";
end

p = struct();
p.Ts_s = 100e-6;
p.inv_Ts_Hz = 1/p.Ts_s;
p.axis_names = ["d";"q"];
p.alpha_initial_A_per_Vs = [1250; 833.333333333333];
p.alpha_min_A_per_Vs = 0.5*p.alpha_initial_A_per_Vs;
p.alpha_max_A_per_Vs = 1.5*p.alpha_initial_A_per_Vs;
p.gamma_alpha = [0.02;0.02];
p.epsilon_alpha_V2 = [1;1];
p.beta_u = [0.05;0.05];
p.beta_y = [0.05;0.05];
p.beta_F = [0.25;0.25];
p.rho_F = [0.5;0.5];
p.N_alpha = 20;
p.excitation_window = 20;
p.u_hp_min_V = [0.5;0.5];
p.E_u_min_V2 = [5;5];
p.regressor_rcond_min = [0.02;0.02];
p.residual_jump_max_A_per_s = [5e4;5e4];
p.max_consecutive_zero_vectors = 3;
p.s2_high_utilization_ratio = 0.90;
p.s2_high_utilization_step_scale = 0.25;
p.duration_tolerance_s = 1e-12;
p.delta_J_A2 = 0.02;
p.delta_mode_gap_A2 = 0.01;
p.alpha_reactivation_good_windows = 3;
p.long_freeze_cycles = 500;
p.F_initial_A_per_s = [0;0];
p.max_abs_F_A_per_s = [5e5;5e5];
p.schema_version = "dual-timescale-design-v1";

switch string(action)
    case "config"
        out = p;
    case "reset"
        out = struct( ...
            'alpha_hat_A_per_Vs',p.alpha_initial_A_per_Vs, ...
            'F_hat_A_per_s',p.F_initial_A_per_s, ...
            'F_previous_A_per_s',p.F_initial_A_per_s, ...
            'u_bar_V',[0;0], ...
            'y_bar_A_per_s',[0;0], ...
            'decision_gate_latched',false, ...
            'alpha_freeze_count',[0;0], ...
            'good_window_count',[0;0], ...
            'history_valid',false, ...
            'sample_index',uint64(0), ...
            'reset_reason',"explicit_or_startup");
    otherwise
        error('DualTimescale:UnknownParameterAction', ...
            'Unknown project_parameter action: %s', string(action));
end
end
