function save_experiment_result(cfg,run_id,name,metrics,trace,pass)
%SAVE_EXPERIMENT_RESULT Save one gated experiment without overwriting a run.
root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
context = zhou_ipmsm.io.create_run_directory(root,name,run_id);
zhou_ipmsm.io.save_configuration_snapshot(cfg,context.snapshot);
metrics.pass = pass;
writetable(metrics,fullfile(context.result,'metrics.csv'));
if strcmp(name,'regression')
    summary_path = fullfile(root,'results','summary','regression_summary.csv');
else
    summary_path = fullfile(root,'results','summary','ipmsm_probe_summary.csv');
end
zhou_ipmsm.io.append_summary_rows(cfg,run_id,name,metrics,summary_path);
zhou_ipmsm.io.export_trace_plot(trace,context.plot,name);
end
