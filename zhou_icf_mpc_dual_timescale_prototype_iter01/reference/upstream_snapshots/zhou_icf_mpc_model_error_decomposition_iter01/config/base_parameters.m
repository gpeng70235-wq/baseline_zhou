function p=base_parameters()
%BASE_PARAMETERS Frozen feasibility-control campaign settings.
p.version="1.0.0";
p.project_name="zhou_icf_mpc_ipmsm_robust_constraint_iter01";
p.random_seed=20250711;
p.Ts_s=100e-6;
p.dc_bus_V=48;
p.voltage_vector_scale=2/3;
p.reference_ramp_s=5e-3;
p.simulation_time_s=0.20;
p.steady_window_start_s=0.10;
p.integration_step_s=2e-6;
p.Jd_limit_A2=0.4^2;
p.Jq_limit_A2=0.4^2;
p.speed_rpm=500;
p.id_ref_A=0;
p.iq_ref_A=20;
p.plot_visible="off";
end
