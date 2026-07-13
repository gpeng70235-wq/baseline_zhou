function e = experiment_definitions(paper, assumptions)
%EXPERIMENT_DEFINITIONS Non-paper settings for the requested acceptance runs.

common = struct();
common.Ts_s = paper.Ts_s;
common.dc_bus_V = assumptions.dc_bus_V;
common.speed_rpm = 100;
common.load_torque_Nm = assumptions.load_torque_Nm;
common.theta0_rad = 0.17;
common.id0_A = 0;
common.iq0_A = 0;
common.id_ref_A = 0;
common.reference_ramp_s = assumptions.current_reference_ramp_s;
common.geometry_tolerance = assumptions.geometry_tolerance;
common.constraint_tolerance = assumptions.constraint_tolerance;

e.C = common;
e.C.simulation_time_s = 0.25;
e.C.steady_window_start_s = 0.10;
e.C.iq_ref_A = paper.independent_test_iq_ref_A;
e.C.fixed_limit_A2 = paper.constraint_fixed_A2;
e.C.sweep_limits_A2 = paper.constraint_sweep_A2;

e.D = common;
e.D.simulation_time_s = 0.30;
e.D.steady_window_start_s = 0.10;
e.D.iq_ref_A = 10;
e.D.Jd_limit_A2 = paper.comparison_Jd_limit_A2;
e.D.Jq_limit_A2 = paper.comparison_Jq_limit_A2;

e.full = common;
e.full.simulation_time_s = 0.20;
e.full.steady_window_start_s = 0.10;
e.full.Jd_limit_A2 = paper.comparison_Jd_limit_A2;
e.full.Jq_limit_A2 = paper.comparison_Jq_limit_A2;
e.full.speeds_rpm = [100,200,300,400,500];
e.full.currents_A = [10,20];
e.full.controller_alpha_values = [1000,750,1250];
end
