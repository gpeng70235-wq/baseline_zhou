function paths = generate_all_plots(project)
%GENERATE_ALL_PLOTS Generate the twenty pre-registered, unsmoothed figures.

root=project.root; run_id=project.run_id; visible=project.base.plot_visible;
p0=readtable(fullfile(root,'results','strict_regression',run_id,'pointwise_comparison.csv'), ...
    'TextType','string');
p0s=readtable(fullfile(root,'results','summary','p0_regression_summary.csv'),'TextType','string');
A1=readtable(fullfile(root,'results','summary','ipmsm_condition_matrix.csv'),'TextType','string');
A2=readtable(fullfile(root,'results','summary','alpha_mode_matrix.csv'),'TextType','string');
A3=readtable(fullfile(root,'results','summary','negative_id_matrix.csv'),'TextType','string');
A4=readtable(fullfile(root,'results','summary','parameter_sensitivity.csv'),'TextType','string');
A6=readtable(fullfile(root,'results','summary','F_estimator_comparison.csv'),'TextType','string');
A7=readtable(fullfile(root,'results','summary','residual_rootcause_summary.csv'),'TextType','string');
A8=readtable(fullfile(root,'results','summary','numerical_closure.csv'),'TextType','string');
paths=strings(20,1); index=0;

f=figure('Visible',visible); hold on;
scenarios=unique(p0.scenario,'stable');
for s=scenarios.'
    rows=p0.scenario==s;
    plot(p0.cycle_index(rows),abs(p0.id_error_A(rows))+eps,'DisplayName',s+' d');
    plot(p0.cycle_index(rows),abs(p0.iq_error_A(rows))+eps,'--','DisplayName',s+' q');
end
set(gca,'YScale','log'); xlabel('control cycle');ylabel('|current difference| (A)');
legend('Location','best'); grid on; title('A0 pointwise current difference (raw)');
[paths,index]=finish(f,'strict_regression','p0_current_pointwise_difference.png', ...
    'A0: 100/300/500 rpm | common Ls | algebraic F | full trace | A',paths,index,project);

f=figure('Visible',visible); values=[p0s.case_match_rate p0s.vector_match_rate ...
    p0s.duration_structure_match_rate]; bar(values); ylim([0 1.05]);
xticklabels(p0s.scenario); xtickangle(20); ylabel('match rate');
legend('Case','vector sequence','nonzero duration structure','Location','southoutside');
title('A0 Case/vector/duration matches'); grid on;
[paths,index]=finish(f,'strict_regression','p0_case_vector_duration_match.png', ...
    'A0: three conditions | common Ls | algebraic F | 0.10-0.20 s | ratio',paths,index,project);

[heat_values,labels]=paired_grid(A1,'id_rmse_A');
f=heat_figure(heat_values,labels,["P0" "P1"],'d-axis RMSE (A)','IPMSM condition d-RMSE');
[paths,index]=finish(f,'condition_matrix','ipmsm_condition_rmse_heatmap.png', ...
    'six conditions | axis-specific | algebraic F | integer-cycle steady windows | A',paths,index,project);
[heat_values,labels]=paired_grid(A1,'thd_percent');
f=heat_figure(heat_values,labels,["P0" "P1"],'phase-a THD (%)','IPMSM condition THD');
[paths,index]=finish(f,'condition_matrix','ipmsm_condition_thd_heatmap.png', ...
    'six conditions | axis-specific | algebraic F | integer-cycle windows | %',paths,index,project);
[heat_values,labels]=paired_grid(A1,'engineering_violation_rate');
f=heat_figure(heat_values,labels,["P0" "P1"],'engineering violation rate','IPMSM constraints');
[paths,index]=finish(f,'condition_matrix','ipmsm_condition_constraint_heatmap.png', ...
    'six conditions | axis-specific | algebraic F | >0.1 A exceedance | ratio',paths,index,project);

f=figure('Visible',visible); tiledlayout(2,1);
nexttile; grouped_alpha(A2,'id_rmse_A'); ylabel('d RMSE (A)');title('d axis');grid on;
nexttile; grouped_alpha(A2,'iq_rmse_A'); ylabel('q RMSE (A)');title('q axis');grid on;
legend('common Ls','axis-specific','Location','southoutside','Orientation','horizontal');
[paths,index]=finish(f,'alpha_matrix','alpha_mode_dq_rmse.png', ...
    'six P1 conditions | both alpha modes | algebraic F | steady window | A',paths,index,project);
f=figure('Visible',visible); tiledlayout(2,1);
nexttile; grouped_alpha(A2,'thd_percent');ylabel('THD (%)');title('raw integer-cycle THD');grid on;
nexttile; grouped_alpha(A2,'switching_actions_per_sample');ylabel('actions/sample');grid on;
[paths,index]=finish(f,'alpha_matrix','alpha_mode_thd_switching.png', ...
    'six P1 conditions | both alpha modes | algebraic F | steady window | %, actions/sample',paths,index,project);

f=figure('Visible',visible); hold on;
trace_dir=fullfile(root,'results','negative_id',run_id);
files=dir(fullfile(trace_dir,'500rpm_20A*csv'));
if isempty(files),files=dir(fullfile(trace_dir,'300rpm_medium_15A*csv'));end
for k=1:numel(files)
    T=readtable(fullfile(files(k).folder,files(k).name),'TextType','string');
    plot(T.time_s,T.id_A,'DisplayName',sprintf('id*=%.3g A',T.id_ref_A(end)));
end
xlabel('time (s)');ylabel('id (A)');legend('Location','best');grid on;
title('Negative-id raw tracking overlay, 500 rpm / 20 A');
[paths,index]=finish(f,'negative_id','negative_id_tracking_overlay.png', ...
    '500 rpm/20 A | axis-specific | algebraic F | full unsmoothed trace | A',paths,index,project);
f=figure('Visible',visible); hold on;
for speed=unique(A3.speed_rpm).'
    rows=A3.speed_rpm==speed;
    plot(A3.id_reference(rows),A3.mean_magnet_torque_Nm(rows),'-o','DisplayName',sprintf('%g rpm magnet',speed));
    plot(A3.id_reference(rows),A3.mean_reluctance_torque_Nm(rows),'--s','DisplayName',sprintf('%g rpm reluctance',speed));
end
xlabel('id reference (A)');ylabel('mean torque (N m)');legend('Location','best');grid on;
title('Negative-id torque components');
[paths,index]=finish(f,'negative_id','negative_id_torque_components.png', ...
    'three conditions | axis-specific | algebraic F | integer-cycle window | N m',paths,index,project);
f=figure('Visible',visible); tiledlayout(2,1);
nexttile; grouped_speed(A3,'thd_percent');ylabel('THD (%)');grid on;
nexttile; grouped_speed(A3,'torque_ripple_Nm');ylabel('torque ripple (N m)');xlabel('id reference (A)');grid on;
[paths,index]=finish(f,'negative_id','negative_id_thd_and_torque_ripple.png', ...
    'three conditions | axis-specific | algebraic F | integer-cycle window | %, N m',paths,index,project);

f=figure('Visible',visible); tiledlayout(2,2);
params=unique(A4.varied_parameter,'stable');
for k=1:numel(params)
    nexttile; rows=A4.varied_parameter==params(k);
    scales=unique(A4.parameter_scale(rows)); values=zeros(size(scales));
    for j=1:numel(scales), values(j)=mean(A4.id_pred_k2_rmse_A(rows&A4.parameter_scale==scales(j))); end
    plot(scales,values,'-o');grid on;xlabel('plant/nominal scale');ylabel('d pred RMSE (A)');title(params(k));
end
[paths,index]=finish(f,'parameter_sensitivity','parameter_sensitivity_spider_or_lines.png', ...
    'low/mid/high conditions | nominal controller | algebraic F | sensitivity only | A',paths,index,project);
f=figure('Visible',visible); hold on;
for k=1:numel(params)
    rows=A4.varied_parameter==params(k); scales=unique(A4.parameter_scale(rows));values=zeros(size(scales));
    for j=1:numel(scales),values(j)=mean(A4.engineering_violation_rate(rows&A4.parameter_scale==scales(j)));end
    plot(scales,values,'-o','DisplayName',params(k));
end
xlabel('plant/nominal scale');ylabel('engineering violation rate');legend;grid on;title('Plant-only parameter sensitivity');
[paths,index]=finish(f,'parameter_sensitivity','parameter_sensitivity_constraint.png', ...
    'low/mid/high | axis-specific nominal controller | algebraic F | >0.1 A | ratio',paths,index,project);

f=figure('Visible',visible); estimator_bar(A6,'id_pred_k2_rmse_A');ylabel('d prediction RMSE (A)');
title('F estimator prediction error');grid on;
[paths,index]=finish(f,'estimator_comparison','F_estimator_prediction_error.png', ...
    'five conditions | axis-specific | algebraic/ESO poles/oracle offline | steady | A',paths,index,project);
f=figure('Visible',visible); estimator_bar(A6,'engineering_violation_rate');ylabel('actual violation rate');
title('F estimator actual constraint violation');grid on;
[paths,index]=finish(f,'estimator_comparison','F_estimator_constraint_violation.png', ...
    'five conditions | axis-specific | Oracle is offline | >0.1 A | ratio',paths,index,project);
f=figure('Visible',visible); hold on;
efiles=dir(fullfile(root,'results','estimator_comparison',run_id,'500rpm_20A*algebraic*csv'));
if isempty(efiles),efiles=dir(fullfile(root,'results','estimator_comparison',run_id,'*algebraic*csv'));end
if ~isempty(efiles)
    T=readtable(fullfile(efiles(1).folder,efiles(1).name));
    valid=isfinite(T.Fd_interval_oracle); plot(T.time_s(valid),T.Fd_estimated(valid),'DisplayName','algebraic Fd');
    plot(T.time_s(valid),T.Fd_interval_oracle(valid),'DisplayName','interval oracle Fd');
end
xlabel('time (s)');ylabel('F_d (A/s)');legend;grid on;title('Estimated F versus noncausal interval oracle');
[paths,index]=finish(f,'estimator_comparison','F_estimated_vs_interval_oracle.png', ...
    '500 rpm/20 A | axis-specific | algebraic vs offline oracle | raw trace | A/s',paths,index,project);

f=figure('Visible',visible); scatter(A3.speed_rpm,A3.id_reference,70,A3.Fd_oracle_rmse,'filled');
xlabel('speed (rpm)');ylabel('id reference (A)');cb=colorbar;cb.Label.String='Fd oracle RMSE (A/s)';grid on;
title('Residual error versus speed and id');
[paths,index]=finish(f,'residual_audit','residual_error_vs_speed_id.png', ...
    'negative-id matrix | axis-specific | algebraic F vs offline oracle | steady | A/s',paths,index,project);
W=readtable(fullfile(root,'results','representative_traces','worst_case_trace.csv'));
f=figure('Visible',visible); groups=logical([W.sector_transition W.case_transition W.command_transition]);
values=zeros(2,3); e=abs(W.prediction_error_d_A);
for j=1:3,values(:,j)=[mean(e(~groups(:,j)),'omitnan');mean(e(groups(:,j)),'omitnan')];end
bar(values);xticklabels({'stable','transition'});legend('sector','Case','command');ylabel('|d pred error| (A)');grid on;
title('Worst-case transition-associated error (raw groups)');
[paths,index]=finish(f,'residual_audit','sector_case_event_error.png', ...
    'worst condition | axis-specific | algebraic F | cycle association | A',paths,index,project);
f=figure('Visible',visible); scatter(A1.speed_rpm,A1.iq_reference,75,A1.voltage_utilization_mean,'filled');
xlabel('speed (rpm)');ylabel('iq reference (A)');cb=colorbar;cb.Label.String='mean voltage utilization';grid on;
title('Voltage utilization map, P0/P1 points');
[paths,index]=finish(f,'residual_audit','voltage_utilization_map.png', ...
    'six paired conditions | axis-specific | algebraic F | steady mean | ratio',paths,index,project);

f=figure('Visible',visible); loglog(A8.integration_step*1e6,A8.endpoint_error_to_finest_A+eps,'-o');
set(gca,'XDir','reverse');xlabel('RK4 maximum step (us)');ylabel('endpoint error to finest (A)');grid on;
title('RK4 switch-boundary convergence');
[paths,index]=finish(f,'summary','rk4_convergence.png', ...
    '300 rpm/20 A | axis-specific | algebraic F | 0.03-0.06 s | A',paths,index,project);
f=figure('Visible',visible);
dashboard=[mean(p0s.pass_fail=="PASS") mean(A1.pass_fail=="PASS") ...
    mean(A2(A2.alpha_mode=="axis_specific",:).id_rmse_A < A2(A2.alpha_mode=="common_Ls",:).id_rmse_A) ...
    mean(A3.illegal_commands==0) max(0,min(1,A7.value(A7.statistic=="offline_oracle_prediction_improvement"))) ...
    mean(A8.numerical_gate=="PASS")];
bar(dashboard);ylim([0 1.05]);xticklabels({'A0','A1 legal','axis d','neg-id legal','oracle gain','A8'});ylabel('gate/evidence score');grid on;
title('Final validation decision dashboard');
[paths,index]=finish(f,'summary','final_decision_dashboard.png', ...
    'all formal evidence | declared alpha/F per source plots | steady windows | normalized',paths,index,project);
assert(index==20,'ZhouValidation:PlotCount','Expected 20 plots, generated %d.',index);
end

function [values,labels]=paired_grid(T,field)
values=reshape(T.(field),2,[]).';labels=T.scenario(1:2:end);
end
function f=heat_figure(values,rows,columns,label,title_text)
f=figure('Visible','off');imagesc(values);colorbar;xticks(1:numel(columns));xticklabels(columns);
yticks(1:numel(rows));yticklabels(rows);xlabel('motor model');ylabel('condition');title(title_text);
cb=colorbar;cb.Label.String=label;
end
function grouped_alpha(T,field)
values=reshape(T.(field),2,[]).';bar(values);xticklabels(T.scenario(1:2:end));xtickangle(20);
end
function grouped_speed(T,field)
hold on; values=T.(field);
for speed=unique(T.speed_rpm).'
    rows=T.speed_rpm==speed;
    plot(T.id_reference(rows),values(rows),'-o','DisplayName',sprintf('%g rpm',speed));
end
legend('Location','best');
end
function estimator_bar(T,field)
label=T.F_estimator;
eso=T.F_estimator=="basic_ESO"; label(eso)="ESO p="+string(T.eso_pole(eso));
cats=unique(label,'stable'); values=zeros(numel(cats),1);
source=T.(field);
for k=1:numel(cats),values(k)=mean(source(label==cats(k)),'omitnan');end
bar(values);xticklabels(cats);xtickangle(25);
end
function [paths,index]=finish(f,category,name,detail,paths,index,project)
index=index+1; directory=fullfile(project.root,'plots',category,project.run_id);
if ~isfolder(directory),mkdir(directory);end
annotation(f,'textbox',[.01 .005 .98 .035],'String', ...
    sprintf('run_id=%s | %s | raw data (no smoothing)',project.run_id,detail), ...
    'EdgeColor','none','HorizontalAlignment','center','FontSize',7,'Interpreter','none');
path_value=fullfile(directory,name);exportgraphics(f,path_value,'Resolution',180);close(f);
paths(index)=string(path_value);
end
