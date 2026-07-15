function p=model_error_parameters()
%MODEL_ERROR_PARAMETERS Frozen settings for the P0-P5 attribution audit.
p.version="1.0.0";p.project_name="zhou_icf_mpc_model_error_decomposition_iter01";
p.random_seed=20260715;p.simulation_time_s=.12;p.steady_window_start_s=.06;
p.Jd_limit_A2=.16;p.Jq_limit_A2=.16;p.integration_step_s=2e-6;
p.candidate_integration_step_s=10e-6;p.predictor_tolerance_A=2e-10;
p.plant_replay_tolerance_A=2e-9;p.repeatability_tolerance=1e-12;
p.minimum_spectrum_cycles=3;p.figure_visible="off";
p.reuse_verified_case_cache=true;p.audit_version="P0P5_v1_20260715";
p.predictor_names=["P0","P1","P2a","P2b","P2c","P3a","P3b","P3c","P4","P5"];
end
