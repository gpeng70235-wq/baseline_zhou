function outcome=run_model_error_decomposition(mode)
%RUN_MODEL_ERROR_DECOMPOSITION Isolated P0-P5 attribution entry.
% CLEAR FUNCTIONS removes local inputs in R2024b, so preserve only dispatch.
if nargin<1||strlength(string(mode))==0,mode="all";else,mode=string(mode);end
setappdata(0,'zhou_model_error_requested_mode',mode);
restoredefaultpath;
rehash toolboxcache;
clear classes;
clear functions;
clear mex;
close all;
clc;
mode=string(getappdata(0,'zhou_model_error_requested_mode'));rmappdata(0,'zhou_model_error_requested_mode');
assert(isscalar(mode)&&ismember(mode,["all","inventory","baseline","audit","prototype"]),'ZhouModelError:InvalidMode');
root=fileparts(mfilename('fullpath'));addpath(root,fullfile(root,'config'),fullfile(root,'src'),fullfile(root,'audit'),fullfile(root,'tests'));
project=initialize_project();zhou_model_error.path_audit(project);
outcome=struct('mode',mode,'project_root',string(root),'run_id',project.run_id);
switch mode
    case "inventory",outcome.inventory=zhou_model_error.inventory(project);
    case "baseline",outcome.inventory=zhou_model_error.inventory(project);outcome.baseline=zhou_model_error.run_baseline_gate(project);
    case "audit",outcome.audit=zhou_model_error.run_audit(project);
    case "prototype",outcome.prototype=zhou_model_error.prototype_gate(project,true);
    otherwise
        outcome.inventory=zhou_model_error.inventory(project);outcome.baseline=zhou_model_error.run_baseline_gate(project);
        assert(outcome.baseline.failed==0,'ZhouModelError:BaselineFailed');
        outcome.audit=zhou_model_error.run_audit(project);outcome.freeze=zhou_model_error.finalize_freeze(project);
        outcome.prototype=zhou_model_error.prototype_gate(project,false);
end
save(fullfile(project.dirs.summary,'last_run_outcome.mat'),'outcome','project');
end
