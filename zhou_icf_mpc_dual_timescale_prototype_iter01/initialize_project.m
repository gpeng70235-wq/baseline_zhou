function project = initialize_project()
%INITIALIZE_PROJECT Build an isolated project configuration.
root = fileparts(mfilename('fullpath'));
addpath(root,fullfile(root,'config'),fullfile(root,'src'));
project = struct();
project.root = root;
project.base = base_parameters();
project.paper = ipmsm_parameters();
project.assumptions = implementation_assumptions();
project.parameters = FROZEN_PROTOTYPE_PARAMETERS();
project.sequence = sequence_parameters();
mp = model_error_parameters();
project.base.random_seed = mp.random_seed;
project.base.simulation_time_s = mp.simulation_time_s;
project.base.steady_window_start_s = mp.steady_window_start_s;
project.base.integration_step_s = mp.integration_step_s;
project.base.Jd_limit_A2 = mp.Jd_limit_A2;
project.base.Jq_limit_A2 = mp.Jq_limit_A2;
project.sequence.simulation_time_s = mp.simulation_time_s;
project.sequence.steady_window_start_s = mp.steady_window_start_s;
project.sequence.decomposition_integration_step_s = mp.integration_step_s;
project.sequence.candidate_integration_step_s = mp.candidate_integration_step_s;
project.sequence.Jd_limit_A2 = .16;
project.sequence.Jq_limit_A2 = .16;
project.run_id = string(datetime('now','Format','yyyyMMdd_HHmmss'))+"_prototype";
project.snapshot_root = fullfile(root,'reference','upstream_snapshots', ...
    'zhou_icf_mpc_model_error_decomposition_iter01');
project.dirs = struct('raw',fullfile(root,'results','raw'), ...
    'summary',fullfile(root,'results','summary'), ...
    'figures',fullfile(root,'results','figures'), ...
    'docs',fullfile(root,'docs'),'audit',fullfile(root,'audit'), ...
    'cache',fullfile(root,'results','cache'));
names = fieldnames(project.dirs);
for k=1:numel(names)
    if ~isfolder(project.dirs.(names{k})), mkdir(project.dirs.(names{k})); end
end
assert(project.paper.Ts_s==100e-6 && project.base.Jd_limit_A2==0.16 && ...
    project.base.Jq_limit_A2==0.16,'Prototype:FrozenControlDrift');
rng(project.parameters.random_seed,'twister');
end
