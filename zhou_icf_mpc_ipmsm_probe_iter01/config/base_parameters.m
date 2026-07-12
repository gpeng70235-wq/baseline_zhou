function parameters = base_parameters()
%BASE_PARAMETERS Shared deterministic probe configuration.
parameters.version = '1.1.0';
parameters.parameter_set = 'zhou2025_ipmsm_probe';
parameters.Ts = 100e-6;
parameters.Vdc = 48;
parameters.speed_rpm = 100;
parameters.iq_ref = 10;
parameters.id_ref = 0;
parameters.reference_ramp_s = 5e-3;
parameters.steps = 500;
parameters.Jd_limit = 0.4^2;
parameters.Jq_limit = 0.4^2;
parameters.alpha_mode = 'axis_specific';
end
