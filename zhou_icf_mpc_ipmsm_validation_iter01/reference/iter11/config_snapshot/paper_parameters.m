function p = paper_parameters()
%PAPER_PARAMETERS Values explicitly reported by Zhou et al. (2025).
% Source: Table III and the text on PDF page 6 / journal page 10536.

p.source = "Zhou et al., IEEE TIE, vol. 72, no. 10, 2025";
p.rated_torque_Nm = 13;
p.rated_speed_rpm = 500;
p.rated_current_A = 19;
p.pole_pairs = 12;
p.Ls_H = 1e-3;
p.Rs_Ohm = 0.0957;
p.psi_f_Wb = 0.027;
p.inertia_kgm2 = 0.01015;
p.alpha_d = 1 / p.Ls_H;
p.alpha_q = 1 / p.Ls_H;
p.Ts_s = 100e-6;
p.dead_time_s = 2e-6;

% Values used in the paper's independent-constraint experiment.
p.constraint_sweep_A2 = [0.4^2, 0.6^2, 0.8^2, 1.0^2];
p.constraint_fixed_A2 = 0.4^2;
p.independent_test_id_ref_A = 0;
p.independent_test_iq_ref_A = 20;
p.independent_test_speed_rpm = 100;

% Values used in the paper's later multiobjective comparison.
p.comparison_Jd_limit_A2 = 0.2^2;
p.comparison_Jq_limit_A2 = 0.15^2;
end

