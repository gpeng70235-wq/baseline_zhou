function p = base_parameters()
%BASE_PARAMETERS Validation-level settings shared by every experiment.

p.version = "1.0.0";
p.project_name = "zhou_icf_mpc_ipmsm_validation_iter01";
p.random_seed = 20250711;
p.Ts_s = 100e-6;
p.ipmsm_dc_bus_V = 48;       % inherited from ipmsm_probe_iter01
p.iter11_dc_bus_V = 84;      % frozen Iteration 11 identified value
p.low_current_A = 10;
p.medium_current_A = 15;
p.high_current_A = 20;
p.rated_current_A = 20;      % probe fallback used for the negative-id scan
p.reference_ramp_s = 5e-3;
p.simulation_time_s = 0.20;
p.steady_window_start_s = 0.10;
p.Jd_limit_A2 = 0.4^2;
p.Jq_limit_A2 = 0.4^2;
p.default_integration_step_s = 2e-6;
p.plot_visible = "off";
p.summary_schema_version = "1.0";
end
