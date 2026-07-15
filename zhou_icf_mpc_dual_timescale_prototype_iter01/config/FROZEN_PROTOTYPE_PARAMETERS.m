function p = FROZEN_PROTOTYPE_PARAMETERS()
%FROZEN_PROTOTYPE_PARAMETERS Preregistered controller-independent constants.
% Values are copied from the frozen design project.  No plant Ld/Lq value is
% read here or by any estimator.
p.schema_version = "dual-timescale-prototype-v1";
p.Ts_s = 100e-6;
p.alpha_initial = [1250; 833.333333333333];
p.alpha_min = 0.5*p.alpha_initial;
p.alpha_max = 1.5*p.alpha_initial;
p.gamma_alpha = [0.02;0.02];
p.epsilon_alpha = [1;1];
p.beta_u = [0.05;0.05];
p.beta_y = [0.05;0.05];
p.beta_F = [0.25;0.25];
p.rho_F = [0.5;0.5];
p.N_alpha = 20;
p.excitation_window = 20;
p.u_hp_min = [0.5;0.5];
p.E_u_min = [5;5];
p.regressor_rcond_min = [0.02;0.02];
p.residual_jump_max = [5e4;5e4];
p.max_zero_vector_run = 3;
p.high_utilization_ratio = 0.90;
p.high_utilization_step_scale = 0.25;
p.duration_tolerance_s = 1e-12;
p.delta_J_A2 = 0.02;
p.delta_mode_gap_A2 = 0.01;
p.reactivation_good_windows = 3;
p.long_freeze_cycles = 500;
p.F_initial = [0;0];
p.F_max = [5e5;5e5];
p.rls_lambda = 0.995;
p.rls_mu_F = 1e-3;
p.rls_P_initial = diag([1e8,1e3]);
p.rls_P_min = 1e-6;
p.rls_P_max = 1e10;
p.disable_excitation = false;
p.freeze_alpha = false;
p.freeze_F = false;
p.disable_reacquire = false;
p.use_pre_s2_voltage = false;
p.calibration_set = ["C01_nominal_100rpm_10A", ...
    "P08_opposed_20pct","D03_id_iq_step"];
p.minimal_set = ["C01_nominal_100rpm_10A", ...
    "P08_opposed_20pct","D03_id_iq_step", ...
    "C07_known_false_safe","C09_S2_boundary"];
p.methods = ["B0","B1","B2","P","RLS"];
p.random_seed = 20260715;
end
