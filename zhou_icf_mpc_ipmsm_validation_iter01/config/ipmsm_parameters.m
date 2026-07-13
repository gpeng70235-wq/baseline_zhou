function motor = ipmsm_parameters()
%IPMSM_PARAMETERS Nominal plant/controller data inherited from the probe.

motor.source = "ipmsm_probe_iter01 with Iteration 11 field aliases";
motor.type = "IPMSM";
motor.model = "P1_salient";
motor.Ld_H = 0.8e-3;
motor.Lq_H = 1.2e-3;
motor.Ls_H = 1.0e-3;
motor.Rs_Ohm = 0.0957;
motor.psi_f_Wb = 0.027;
motor.pole_pairs = 12;
motor.inertia_kgm2 = 0.01015;
motor.rated_current_A = 20;
motor.rated_speed_rpm = 500;
motor.rated_torque_Nm = 13;
motor.alpha_d = 1/motor.Ld_H;
motor.alpha_q = 1/motor.Lq_H;
motor.Ts_s = 100e-6;
motor.dead_time_s = 2e-6;
motor.constraint_fixed_A2 = 0.4^2;
motor.comparison_Jd_limit_A2 = 0.4^2;
motor.comparison_Jq_limit_A2 = 0.4^2;
end
