function p=sequence_parameters()
%SEQUENCE_PARAMETERS Frozen settings for the independent decomposition audit.
p.version="1.0.0";
p.project_name="zhou_icf_mpc_sequence_decomposition_iter01";
p.random_seed=20260715;
p.simulation_time_s=0.12;
p.steady_window_start_s=0.06;
p.Jd_limit_A2=0.16;
p.Jq_limit_A2=0.16;
p.decomposition_integration_step_s=2e-6;
p.candidate_integration_step_s=10e-6;
p.ultralocal_identity_tolerance_A=2e-10;
p.plant_replay_tolerance_A=2e-9;
p.closure_tolerance_A=5e-12;
p.repeatability_tolerance=1e-12;
p.figure_visible="off";
end
