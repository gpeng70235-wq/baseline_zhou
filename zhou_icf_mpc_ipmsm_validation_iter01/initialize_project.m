function project = initialize_project(requested_run_id)
%INITIALIZE_PROJECT Establish an isolated, deterministic validation runtime.

arguments
    requested_run_id (1,1) string = ""
end

root = fileparts(mfilename('fullpath'));
restoredefaultpath;
code_paths = {root, fullfile(root,'config'), fullfile(root,'experiments'), ...
    fullfile(root,'estimators'), fullfile(root,'src'), fullfile(root,'tests')};
for k = 1:numel(code_paths)
    addpath(code_paths{k});
end

entries = string(strsplit(path,pathsep));
forbidden_tokens = ["zhou_icf_mpc_reproduction_iter10", ...
    "zhou_icf_mpc_reproduction_iter11", ...
    "zhou_iter11_residual_daxis_audit_iter01", ...
    "zhou_icf_mpc_ipmsm_probe_iter01", "baseline_wu", ...
    "wu2025_pdvm", "wu_reproduction"];
polluted = false(size(entries));
for token = forbidden_tokens
    polluted = polluted | contains(lower(entries),lower(token));
end

project = struct();
project.root = root;
project.base = base_parameters();
project.motor = ipmsm_parameters();
project.paper = project.motor; % compatibility with both independent runners
project.assumptions = implementation_assumptions();
project.thresholds = acceptance_thresholds();
project.mismatches = parameter_mismatch_definitions();
project.estimators = estimator_definitions(project.base.Ts_s);
project.experiments = experiment_matrix(project.base);
project.matlab_version = version;
project.initialized_at = datetime('now','TimeZone','local');
project.timestamp = string(datetime('now','Format','yyyy-MM-dd''T''HH:mm:ss.SSSXXX'));
if strlength(requested_run_id)==0
    project.run_id = unique_run_id(root);
else
    project.run_id = requested_run_id;
end

rng(project.base.random_seed,'twister');
experiment_dirs = ["strict_regression" "condition_matrix" "alpha_matrix" ...
    "negative_id" "parameter_sensitivity" "parameter_stress" ...
    "estimator_comparison" "residual_audit" "numerical_closure" ...
    "representative_traces"];
for name = experiment_dirs
    ensure_folder(fullfile(root,'results',name,project.run_id));
end
plot_dirs = ["strict_regression" "condition_matrix" "alpha_matrix" ...
    "negative_id" "parameter_sensitivity" "estimator_comparison" ...
    "residual_audit" "summary"];
for name = plot_dirs
    ensure_folder(fullfile(root,'plots',name,project.run_id));
end
snapshot_dir = fullfile(root,'results','summary',project.run_id,'config_snapshot');
ensure_folder(snapshot_dir);
save(fullfile(snapshot_dir,'configuration.mat'),'project');

resolved = strings(0,2);
probes = ["zhou_iter11_ref.sim.run_closed_loop" ...
    "zhou_ipmsm.sim.run_closed_loop" ...
    "zhou_ipmsm.controller.icf_mpc_step" ...
    "zhou_validation.compare_pointwise_runs"];
for probe = probes
    location = string(which(probe));
    resolved(end+1,:) = [probe location]; %#ok<AGROW>
    if strlength(location)>0
        assert(startsWith(lower(location),lower(string(root))), ...
            'ZhouValidation:IsolationViolation', ...
            'Function resolution escaped the new project: %s -> %s',probe,location);
    end
end
write_path_audit(project,entries,polluted,resolved,forbidden_tokens);
assert(~any(polluted),'ZhouValidation:IsolationViolation', ...
    'Forbidden legacy project path(s) detected: %s', ...
    strjoin(entries(polluted),newline));
end

function id = unique_run_id(root)
base = char(datetime('now','Format','yyyyMMdd_HHmmss'));
id = string(base + "_ipmsm_validation");
suffix = 1;
while isfolder(fullfile(root,'results','strict_regression',id))
    id = string(sprintf('%s_%02d_ipmsm_validation',base,suffix));
    suffix = suffix+1;
end
end

function ensure_folder(path_value)
if ~isfolder(path_value)
    mkdir(path_value);
end
end

function write_path_audit(project,entries,polluted,resolved,tokens)
path_value = fullfile(project.root,'diagnostics','path_isolation_audit.md');
fid = fopen(path_value,'w','n','UTF-8');
assert(fid>=0,'ZhouValidation:AuditOpen','Cannot write path isolation audit.');
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'# Path isolation audit\n\n');
fprintf(fid,'- run_id: `%s`\n- initialized: `%s`\n',project.run_id,project.timestamp);
fprintf(fid,'- project root: `%s`\n- result: **%s**\n\n',project.root, ...
    pass_text(~any(polluted)));
fprintf(fid,'## Forbidden tokens\n\n');
for token = tokens
    fprintf(fid,'- `%s`\n',token);
end
fprintf(fid,'\n## Package resolution\n\n| symbol | resolved path | inside project |\n|---|---|---:|\n');
for k = 1:size(resolved,1)
    inside = startsWith(lower(resolved(k,2)),lower(string(project.root)));
    fprintf(fid,'| `%s` | `%s` | %s |\n',resolved(k,1),resolved(k,2),pass_text(inside));
end
fprintf(fid,'\n## MATLAB path entries\n\n');
for k = 1:numel(entries)
    fprintf(fid,'- `%s`%s\n',entries(k),conditional_pollution(polluted(k)));
end
end

function value = conditional_pollution(is_polluted)
if is_polluted, value=' **FORBIDDEN**'; else, value=''; end
end

function value = pass_text(condition)
if condition, value='PASS'; else, value='FAIL'; end
end
