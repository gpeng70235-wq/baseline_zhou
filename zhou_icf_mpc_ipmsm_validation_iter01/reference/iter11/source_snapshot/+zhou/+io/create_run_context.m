function ctx = create_run_context(project, tag)
%CREATE_RUN_CONTEXT Create non-overwriting result/plot/diagnostic directories.

arguments
    project struct
    tag (1,1) string
end

safe_tag = regexprep(lower(tag), '[^a-z0-9_-]', '_');
stamp = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS'));
base_id = stamp + "_" + safe_tag;

results_root = fullfile(project.root, 'results');
plots_root = fullfile(project.root, 'plots');
diagnostics_root = fullfile(project.root, 'diagnostics');
ensure_dir(results_root);
ensure_dir(plots_root);
ensure_dir(diagnostics_root);
ensure_dir(fullfile(results_root, 'runs'));
ensure_dir(fullfile(diagnostics_root, 'runs'));

run_id = base_id;
suffix = 0;
while isfolder(fullfile(results_root, 'runs', run_id)) || ...
        isfolder(fullfile(plots_root, run_id)) || ...
        isfolder(fullfile(diagnostics_root, 'runs', run_id))
    suffix = suffix + 1;
    run_id = base_id + "_" + compose('%02d', suffix);
end

ctx = struct();
ctx.run_id = run_id;
ctx.project_root = project.root;
ctx.results_root = results_root;
ctx.plots_root = plots_root;
ctx.diagnostics_root = diagnostics_root;
ctx.results_dir = fullfile(results_root, 'runs', run_id);
ctx.plots_dir = fullfile(plots_root, run_id);
ctx.diagnostics_dir = fullfile(diagnostics_root, 'runs', run_id);

[ok1, msg1] = mkdir(ctx.results_dir);
[ok2, msg2] = mkdir(ctx.plots_dir);
[ok3, msg3] = mkdir(ctx.diagnostics_dir);
assert(ok1 && ok2 && ok3, 'Zhou:RunDirectoryCreationFailed', ...
    'Could not create unique run directories: %s | %s | %s', msg1, msg2, msg3);

snapshot_path = fullfile(ctx.results_dir, 'config_snapshot.mat');
paper = project.paper; %#ok<NASGU>
assumptions = project.assumptions; %#ok<NASGU>
pointwise_targets = project.pointwise_targets; %#ok<NASGU>
matlab_version = project.matlab_version; %#ok<NASGU>
created_at = datetime('now', 'TimeZone', 'local'); %#ok<NASGU>
save(snapshot_path, 'paper', 'assumptions', 'pointwise_targets', ...
    'matlab_version', 'created_at');
ctx.code_manifest_sha256 = zhou.io.write_code_manifest(project.root, ...
    fullfile(ctx.results_dir,'code_manifest.csv'));
end

function ensure_dir(pathname)
if ~isfolder(pathname)
    mkdir(pathname);
end
end
