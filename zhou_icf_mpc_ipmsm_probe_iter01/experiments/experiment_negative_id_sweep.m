function pass = experiment_negative_id_sweep(cfg, run_id)
%EXPERIMENT_NEGATIVE_ID_SWEEP Exercise the complete nonzero-d-axis path.
root = fileparts(fileparts(mfilename('fullpath')));
rows = table();
for id_reference = cfg.experiments.negative_id
    condition = cfg;
    condition.id_ref = id_reference;
    metric = zhou_ipmsm.run_probe_case(condition);
    metric.id_reference = id_reference;
    rows = [rows;metric]; %#ok<AGROW>
end
reluctance_gain = rows.mean_reluctance_torque_Nm(end) - ...
    rows.mean_reluctance_torque_Nm(1);
rows.endpoint_reluctance_gain_Nm = repmat(reluctance_gain,height(rows),1);
pass = all_common_acceptance(rows,cfg.acceptance) && ...
    reluctance_gain>=cfg.acceptance.min_negative_id_reluctance_gain_Nm;
rows.pass = repmat(pass,height(rows),1);

context = zhou_ipmsm.io.create_run_directory(root,'negative_id',run_id);
snapshot_cfg = cfg;
snapshot_cfg.executed_id_references = cfg.experiments.negative_id;
zhou_ipmsm.io.save_configuration_snapshot(snapshot_cfg,context.snapshot);
writetable(rows,fullfile(context.result,'metrics.csv'));
zhou_ipmsm.io.append_summary_rows(cfg,run_id,'negative_id',rows, ...
    fullfile(root,'results','summary','negative_id_sweep.csv'));
plot_negative_id_sweep(rows,context.plot);
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

function plot_negative_id_sweep(rows,plot_directory)
f = figure('Visible','off','Color','w','Position',[100 100 850 420]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile; plot(rows.id_reference,rows.mean_torque_Nm,'o-','LineWidth',1.2); hold on;
plot(rows.id_reference,rows.mean_reluctance_torque_Nm,'s-','LineWidth',1.2);
xlabel('i_d^* (A)'); ylabel('torque (N m)'); legend('total','reluctance'); grid on;
nexttile; plot(rows.id_reference,rows.rmse_d_A,'o-','LineWidth',1.2); hold on;
plot(rows.id_reference,rows.rmse_q_A,'s-','LineWidth',1.2);
xlabel('i_d^* (A)'); ylabel('RMSE (A)'); legend('d axis','q axis'); grid on;
sgtitle('Negative-d-axis reference sweep');
exportgraphics(f,fullfile(plot_directory,'negative_id_sweep.png'),'Resolution',160);
close(f);
end
