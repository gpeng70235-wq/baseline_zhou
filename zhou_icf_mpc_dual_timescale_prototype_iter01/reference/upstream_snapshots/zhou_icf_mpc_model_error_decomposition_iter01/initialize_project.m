function project=initialize_project(requested_run_id)
%INITIALIZE_PROJECT Resolve only local frozen copies and new audit code.
arguments,requested_run_id (1,1) string="",end
root=fileparts(mfilename('fullpath'));
for p={root,fullfile(root,'config'),fullfile(root,'src'),fullfile(root,'audit'),fullfile(root,'tests')}
    if isfolder(p{1}),addpath(p{1});end
end
project=struct('root',root,'base',base_parameters(),'paper',ipmsm_parameters(), ...
    'assumptions',implementation_assumptions(),'sequence',sequence_parameters(), ...
    'model_error',model_error_parameters(),'thresholds',acceptance_thresholds());
project.motor=project.paper;project.base.project_name=project.model_error.project_name;
project.base.random_seed=project.model_error.random_seed;
project.base.simulation_time_s=project.model_error.simulation_time_s;
project.base.steady_window_start_s=project.model_error.steady_window_start_s;
project.base.integration_step_s=project.model_error.integration_step_s;
project.base.Jd_limit_A2=project.model_error.Jd_limit_A2;project.base.Jq_limit_A2=project.model_error.Jq_limit_A2;
project.sequence.simulation_time_s=project.model_error.simulation_time_s;
project.sequence.steady_window_start_s=project.model_error.steady_window_start_s;
project.sequence.decomposition_integration_step_s=project.model_error.integration_step_s;
project.sequence.candidate_integration_step_s=project.model_error.candidate_integration_step_s;
project.sequence.Jd_limit_A2=.16;project.sequence.Jq_limit_A2=.16;
if strlength(requested_run_id)==0,project.run_id=string(char(datetime('now','Format','yyyyMMdd_HHmmss'))+"_model_error");else,project.run_id=requested_run_id;end
project.timestamp=string(datetime('now','TimeZone','Asia/Shanghai', ...
    'Format','yyyy-MM-dd''T''HH:mm:ss.SSSXXX'));
project.upstreams=zhou_model_error.discover_upstreams(project);
project.dirs=struct('raw',fullfile(root,'results','raw'),'summary',fullfile(root,'results','summary'), ...
    'figures',fullfile(root,'results','figures'),'docs',fullfile(root,'docs'));
for f=fieldnames(project.dirs).',ensure(project.dirs.(f{1}));end;ensure(fullfile(project.dirs.raw,'mat'));
assert(project.model_error.Jd_limit_A2==.16&&project.model_error.Jq_limit_A2==.16,'ZhouModelError:ConstraintDrift');
rng(project.model_error.random_seed,'twister');
end
function ensure(p),if ~isfolder(p),mkdir(p);end,end
