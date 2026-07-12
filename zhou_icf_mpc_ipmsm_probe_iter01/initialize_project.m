function cfg = initialize_project()
%INITIALIZE_PROJECT Reset MATLAB and expose only this independent project.
root = fileparts(mfilename('fullpath'));
restoredefaultpath;
user_path_entries = split(string(userpath),pathsep);
for index = 1:numel(user_path_entries)
    candidate = strtrim(user_path_entries(index));
    if strlength(candidate)>0 && contains(string(path()),candidate)
        rmpath(candidate);
    end
end

source_directories = {'config','src','experiments','tests','docs','reference'};
for index = 1:numel(source_directories)
    directory_path = fullfile(root,source_directories{index});
    assert(isfolder(directory_path),'ZhouIPMSM:MissingProjectDirectory', ...
        'Required project directory is missing: %s',directory_path);
end
output_directories = { ...
    'results','results/regression','results/saliency','results/alpha_comparison', ...
    'results/negative_id','results/summary','plots','plots/regression', ...
    'plots/saliency','plots/alpha_comparison','plots/negative_id', ...
    'diagnostics','diagnostics/runtime_errors','logs'};
for index = 1:numel(output_directories)
    directory_path = fullfile(root,strrep(output_directories{index},'/',filesep));
    if ~isfolder(directory_path)
        mkdir(directory_path);
    end
end

addpath(root,fullfile(root,'config'),fullfile(root,'src'), ...
    fullfile(root,'experiments'),fullfile(root,'tests'));
current_matlab_path = path();
entries = split(string(current_matlab_path),pathsep);
workspace_root = lower(string(fileparts(root)));
project_root = lower(string(root));
in_workspace = startsWith(lower(entries),workspace_root+filesep);
in_project = startsWith(lower(entries),project_root);
forbidden_tokens = ["reproduction_iter10" "reproduction_iter11" ...
    "residual_daxis_audit" "zhou_icf_mpc_reproduction" "wu_"];
token_hit = false(size(entries));
for index = 1:numel(forbidden_tokens)
    token_hit = token_hit | contains(lower(entries),forbidden_tokens(index));
end
bad = (in_workspace & ~in_project) | token_hit;
if any(bad)
    audit = fullfile(root,'diagnostics','path_isolation_audit.md');
    fid = fopen(audit,'w','n','UTF-8');
    if fid>=0
        fprintf(fid,'# MATLAB path isolation audit\n\n- timestamp: %s\n- status: **FAIL**\n- forbidden entries: `%s`\n', ...
            char(datetime('now')),strjoin(entries(bad),'`, `'));
        fclose(fid);
    end
    error('ZhouIPMSM:PathIsolation', ...
        'External Zhou/Wu/audit project path detected: %s',strjoin(entries(bad),', '));
end

rng(20260712,'twister');
cfg = base_parameters();
cfg.motor = ipmsm_parameters();
cfg.experiments = experiment_definitions();
cfg.acceptance = acceptance_thresholds();
cfg.assumptions = implementation_assumptions();
assert(cfg.steps>=4 && cfg.Ts>0 && cfg.reference_ramp_s>=0, ...
    'ZhouIPMSM:InvalidBaseConfiguration','Simulation configuration is invalid.');
assert(isfile(fullfile(root,'SOURCE_MANIFEST.sha256')), ...
    'ZhouIPMSM:MissingManifest','SOURCE_MANIFEST.sha256 is missing.');

audit = fullfile(root,'diagnostics','path_isolation_audit.md');
fid = fopen(audit,'w','n','UTF-8');
assert(fid>=0,'ZhouIPMSM:AuditOpen','Cannot write path-isolation audit.');
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,['# MATLAB path isolation audit\n\n- timestamp: %s\n' ...
    '- project: `%s`\n- version: `%s`\n- status: **PASS**\n' ...
    '- external project paths: none\n- MATLAB userpath removed: yes\n' ...
    '- path entry count: %d\n\n```text\n%s\n```\n'], ...
    char(datetime('now')),root,cfg.version,numel(entries),strjoin(entries,newline));
clear cleanup;
fprintf('Zhou IPMSM probe v%s; isolated path PASS\nRoot: %s\nManifest: %s\n', ...
    cfg.version,root,fullfile(root,'SOURCE_MANIFEST.sha256'));
end
