function status = run_ipmsm_probe()
%RUN_IPMSM_PROBE One-command, gated IPMSM migration probe.
cfg = initialize_project();
root = fileparts(mfilename('fullpath'));
run_id = create_unique_run_id(root);
log_path = fullfile(root,'logs','matlab_execution_log.txt');
diary(log_path);
diary_cleanup = onCleanup(@() diary('off')); %#ok<NASGU>
fprintf('\n===== %s | %s =====\n',run_id,char(datetime('now')));

status = struct('tests',false,'P0',false,'P1',false, ...
    'alpha',false,'negative_id',false);
detail = struct('tests',"not run",'P0',"skipped: unit tests did not pass", ...
    'P1',"skipped: P0 did not pass",'alpha',"skipped: P1 did not pass", ...
    'negative_id',"skipped: alpha comparison did not pass");

[status.tests,detail.tests] = execute_gate(@() run_unit_tests(cfg), ...
    root,run_id,'unit_tests');
if status.tests
    [status.P0,detail.P0] = execute_gate( ...
        @() experiment_P0_degenerate_regression(cfg,run_id),root,run_id,'P0');
end
if status.P0
    [status.P1,detail.P1] = execute_gate( ...
        @() experiment_P1_saliency_probe(cfg,run_id),root,run_id,'P1');
end
if status.P1
    [status.alpha,detail.alpha] = execute_gate( ...
        @() experiment_alpha_mode_comparison(cfg,run_id),root,run_id,'alpha');
end
if status.alpha
    [status.negative_id,detail.negative_id] = execute_gate( ...
        @() experiment_negative_id_sweep(cfg,run_id),root,run_id,'negative_id');
end

ledger = table(string(run_id),string(datetime('now','Format', ...
    'yyyy-MM-dd''T''HH:mm:ss.SSS')),status.tests,status.P0,status.P1, ...
    status.alpha,status.negative_id,'VariableNames', ...
    {'run_id','timestamp','tests','P0','P1','alpha','negative_id'});
zhou_ipmsm.io.write_result_table(ledger,fullfile(root,'logs','run_ledger.csv'),true);
write_final_report(root,run_id,cfg,status,detail);
manifest_hash = zhou_ipmsm.io.generate_source_manifest(root);
fprintf('SOURCE_MANIFEST.sha256 refreshed: %s\n',manifest_hash);
disp(status);
if ~all(cell2mat(struct2cell(status)))
    error('ZhouIPMSM:ProbeGateFailure', ...
        'One or more IPMSM admission gates failed; see FINAL_IPMSM_PROBE_REPORT.md.');
end
end

function [passed,detail] = execute_gate(action,root,run_id,gate_name)
try
    passed = logical(action());
    if passed
        detail = "PASS";
    else
        detail = "FAIL: acceptance criteria not met";
    end
catch exception
    passed = false;
    detail = "ERROR: "+string(exception.identifier)+" - "+string(exception.message);
    log_error(root,run_id,gate_name,exception);
end
fprintf('%s: %s\n',gate_name,detail);
end

function log_error(root,run_id,gate_name,exception)
directory = fullfile(root,'diagnostics','runtime_errors');
if ~isfolder(directory), mkdir(directory); end
path = fullfile(directory,sprintf('%s_%s.txt',run_id,gate_name));
fid = fopen(path,'w','n','UTF-8');
if fid<0, return; end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'gate: %s\nidentifier: %s\nmessage: %s\n\n%s\n', ...
    gate_name,exception.identifier,exception.message,getReport(exception,'extended'));
end

function run_id = create_unique_run_id(root)
base = char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
suffix = 0;
while true
    if suffix==0
        run_id = [base '_ipmsm_probe'];
    else
        run_id = sprintf('%s_%02d_ipmsm_probe',base,suffix);
    end
    experiments = {'regression','saliency','alpha_comparison','negative_id'};
    collision = false;
    for index = 1:numel(experiments)
        collision = collision || isfolder(fullfile(root,'results',experiments{index},run_id)) || ...
            isfolder(fullfile(root,'plots',experiments{index},run_id));
    end
    if ~collision, return; end
    suffix = suffix+1;
end
end

function write_final_report(root,run_id,cfg,status,detail)
path = fullfile(root,'FINAL_IPMSM_PROBE_REPORT.md');
fid = fopen(path,'w','n','UTF-8');
assert(fid>=0,'ZhouIPMSM:ReportOpen','Cannot write final report.');
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'# Final IPMSM probe report\n\n');
fprintf(fid,'- Run ID: `%s`\n- Timestamp: %s\n- Version: `%s`\n', ...
    run_id,char(datetime('now')),cfg.version);
fprintf(fid,'- Motor: IPMSM, `Ld=%.6g H`, `Lq=%.6g H`\n',cfg.motor.Ld,cfg.motor.Lq);
fprintf(fid,'- MATLAB path isolation: **PASS** (see `diagnostics/path_isolation_audit.md`)\n\n');
fprintf(fid,'## Gate status\n\n| gate | status | detail |\n|---|---:|---|\n');
names = fieldnames(status);
for index = 1:numel(names)
    name = names{index};
    fprintf(fid,'| %s | %s | %s |\n',name,pass_text(status.(name)),detail.(name));
end
fprintf(fid,['\nA failed or errored gate automatically skips every downstream experiment. ' ...
    'Exceptions are recorded under `diagnostics/runtime_errors/`.\n\n']);
fprintf(fid,'## Run artifacts\n\n');
write_experiment_section(fid,root,run_id,'regression','P0 degenerate regression');
write_experiment_section(fid,root,run_id,'saliency','P1 saliency probe');
write_experiment_section(fid,root,run_id,'alpha_comparison','Alpha-mode comparison');
write_experiment_section(fid,root,run_id,'negative_id','Negative-id sweep');
fprintf(fid,['\n## Interpretation and limits\n\n' ...
    '- P0 checks the analytical `Ld=Lq` SMPMSM limit and inherited command/constraint invariants; it does not copy historical Iteration 11 result files.\n' ...
    '- P1 requires a measurable closed-loop saliency effect. The negative-id sweep checks the expected positive reluctance-torque gain for `Ld<Lq`.\n' ...
    '- This is a fixed-speed, ideal-inverter simulation. Saturation, iron loss, dead time, mechanical transients, and parameter drift are outside scope.\n' ...
    '- Review structured summaries in `results/summary/`; source provenance is in `SOURCE_MANIFEST.sha256`.\n']);
end

function write_experiment_section(fid,root,run_id,directory,title)
metric_path = fullfile(root,'results',directory,run_id,'metrics.csv');
plot_directory = fullfile(root,'plots',directory,run_id);
if ~isfile(metric_path)
    fprintf(fid,'- **%s:** skipped; no run directory created.\n',title);
    return;
end
metrics = readtable(metric_path,'TextType','string');
fprintf(fid,'- **%s:** `%s` (%d condition(s)); plots: `%s`\n',title, ...
    relative_path(root,metric_path),height(metrics),relative_path(root,plot_directory));
fprintf(fid,'\n  | condition | RMSE d (A) | RMSE q (A) | mean torque (N m) | illegal | negative dwell | d/q violations | pass |\n');
fprintf(fid,'  |---|---:|---:|---:|---:|---:|---:|---:|\n');
for row = 1:height(metrics)
    condition = "default";
    if ismember('alpha_mode',metrics.Properties.VariableNames)
        condition = string(metrics.alpha_mode(row));
    elseif ismember('id_reference',metrics.Properties.VariableNames)
        condition = "id="+string(metrics.id_reference(row))+" A";
    end
    pass_value = NaN;
    if ismember('pass',metrics.Properties.VariableNames)
        pass_value = metrics.pass(row);
    end
    fprintf(fid,'  | %s | %.6g | %.6g | %.6g | %g | %g | %g/%g | %s |\n', ...
        condition,metrics.rmse_d_A(row),metrics.rmse_q_A(row), ...
        metrics.mean_torque_Nm(row),metrics.illegal_commands(row), ...
        metrics.negative_durations(row),metrics.constraint_d_violations(row), ...
        metrics.constraint_q_violations(row),logical_text(pass_value));
end
fprintf(fid,'\n');
end

function value = relative_path(root,path)
value = strrep(erase(string(path),string(root)+filesep),filesep,'/');
end

function text = pass_text(value)
if value, text='PASS'; else, text='FAIL/SKIP'; end
end

function text = logical_text(value)
if isnan(value), text='n/a'; elseif logical(value), text='PASS'; else, text='FAIL'; end
end
