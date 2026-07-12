function pass = experiment_alpha_mode_comparison(cfg, run_id)
%EXPERIMENT_ALPHA_MODE_COMPARISON Axis-specific IPMSM alpha versus common Ls.
root = fileparts(fileparts(mfilename('fullpath')));
rows = table();
traces = cell(numel(cfg.experiments.alpha_modes),1);
for mode_index = 1:numel(cfg.experiments.alpha_modes)
    condition = cfg;
    condition.alpha_mode = cfg.experiments.alpha_modes{mode_index};
    [metric,trace] = zhou_ipmsm.run_probe_case(condition);
    metric.alpha_mode = string(condition.alpha_mode);
    rows = [rows;metric]; %#ok<AGROW>
    traces{mode_index} = trace;
end
mode_delta = norm([diff(rows.rmse_d_A) diff(rows.rmse_q_A) ...
    diff(rows.mean_torque_Nm) diff(rows.switching_actions_per_step)]);
rows.alpha_mode_metric_delta = repmat(mode_delta,height(rows),1);
pass = all_common_acceptance(rows,cfg.acceptance) && ...
    mode_delta>=cfg.acceptance.min_alpha_mode_metric_delta;
rows.pass = repmat(pass,height(rows),1);

context = zhou_ipmsm.io.create_run_directory(root,'alpha_comparison',run_id);
snapshot_cfg = cfg;
snapshot_cfg.executed_alpha_modes = cfg.experiments.alpha_modes;
zhou_ipmsm.io.save_configuration_snapshot(snapshot_cfg,context.snapshot);
writetable(rows,fullfile(context.result,'metrics.csv'));
zhou_ipmsm.io.append_summary_rows(cfg,run_id,'alpha_comparison',rows, ...
    fullfile(root,'results','summary','alpha_mode_comparison.csv'));
plot_alpha_comparison(rows,context.plot);
end

function pass = all_common_acceptance(rows,thresholds)
pass = all(rows.illegal_commands<=thresholds.max_illegal) && ...
    all(rows.negative_durations==0) && ...
    all(rows.constraint_d_violations<=thresholds.max_constraint_violations) && ...
    all(rows.constraint_q_violations<=thresholds.max_constraint_violations) && ...
    all(rows.geometry_reference_outside<=thresholds.max_geometry_outside) && ...
    all(rows.saturated_commands<=thresholds.max_saturated_commands) && ...
    all(rows.rmse_d_A<=thresholds.max_rmse_A) && ...
    all(rows.rmse_q_A<=thresholds.max_rmse_A) && ...
    all(rows.phase_a_thd<=thresholds.max_phase_a_thd);
end

function plot_alpha_comparison(rows,plot_directory)
f = figure('Visible','off','Color','w','Position',[100 100 850 420]);
tiledlayout(1,2,'TileSpacing','compact');
axis_left = nexttile; bar(categorical(rows.alpha_mode),[rows.rmse_d_A rows.rmse_q_A]);
axis_left.TickLabelInterpreter = 'none';
ylabel('RMSE (A)'); legend('d axis','q axis','Location','best'); grid on;
axis_right = nexttile; bar(categorical(rows.alpha_mode),rows.switching_actions_per_step);
axis_right.TickLabelInterpreter = 'none';
ylabel('switching actions/sample'); grid on;
sgtitle('IPMSM alpha-mode comparison');
exportgraphics(f,fullfile(plot_directory,'alpha_mode_comparison.png'),'Resolution',160);
close(f);
end
