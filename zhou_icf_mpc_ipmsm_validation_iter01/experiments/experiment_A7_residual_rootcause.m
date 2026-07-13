function [summary,worst_trace] = experiment_A7_residual_rootcause( ...
        project,A1,A2delta,A3,A6)
%EXPERIMENT_A7_RESIDUAL_ROOTCAUSE Evidence table; associations are not causality.

p1=A1(A1.pair_role=="P1",:); p0=A1(A1.pair_role=="P0",:);
valid_pair=p1.pass_fail=="PASS" & p0.pass_fail=="PASS";
valid_p1=p1(valid_pair,:);valid_p0=p0(valid_pair,:);
[~,idx]=max(valid_p1.id_pred_k2_rmse_A+valid_p1.iq_pred_k2_rmse_A);
scenario_name=valid_p1.scenario(idx);
scenario_idx=find(string({project.experiments.name})==scenario_name,1);
assert(~isempty(scenario_idx),'ZhouValidation:A7Scenario','Worst scenario not found.');
s=project.experiments(scenario_idx); s.motor_model="P1";
s.alpha_mode="axis_specific"; s.F_estimator="algebraic_iter11";
[~,worst_trace,~]=zhou_validation.execute_ipmsm_case(project,s,"residual_audit",true);

err=hypot(worst_trace.prediction_error_d_A,worst_trace.prediction_error_q_A);
sector_ratio=event_ratio(err,worst_trace.sector_transition);
case_ratio=event_ratio(err,worst_trace.case_transition);
command_ratio=event_ratio(err,worst_trace.command_transition);
voltage_corr=corr_safe(err,worst_trace.voltage_utilization);

neg0=A3(A3.id_reference==0 & A3.pass_fail=="PASS",:);
negmin=A3(A3.id_reference==min(A3.id_reference) & A3.pass_fail=="PASS",:);
base6=A6(A6.F_estimator=="algebraic_iter11" & A6.pass_fail=="PASS",:);
oracle6=A6(A6.F_estimator=="interval_F_oracle_offline" & A6.pass_fail=="OFFLINE_ONLY",:);
eso6=A6(A6.F_estimator=="basic_ESO" & A6.pass_fail=="PASS",:);
oracle_improvement=1-mean(oracle6.id_pred_k2_rmse_A+oracle6.iq_pred_k2_rmse_A,'omitnan')/ ...
    max(mean(base6.id_pred_k2_rmse_A+base6.iq_pred_k2_rmse_A,'omitnan'),eps);
if isempty(eso6), eso_improvement=NaN;
else
    eso_improvement=1-min(mean_by_pole(eso6,height(base6)),[],'omitnan')/ ...
        max(mean(base6.id_pred_k2_rmse_A+base6.iq_pred_k2_rmse_A,'omitnan'),eps);
end

statistic=["P1_minus_P0_d_prediction_RMSE_A"; ...
    "P1_minus_P0_q_prediction_RMSE_A";"P1_vs_P0_d_residual_ratio"; ...
    "negative_id_Fd_oracle_RMSE_delta";"sector_transition_error_ratio"; ...
    "case_transition_error_ratio";"command_transition_error_ratio"; ...
    "prediction_error_voltage_utilization_correlation"; ...
    "axis_specific_mean_d_RMSE_delta_A";"offline_oracle_prediction_improvement"; ...
    "best_ESO_prediction_improvement"];
value=[mean(valid_p1.id_pred_k2_rmse_A-valid_p0.id_pred_k2_rmse_A); ...
    mean(valid_p1.iq_pred_k2_rmse_A-valid_p0.iq_pred_k2_rmse_A); ...
    mean(valid_p1.id_pred_k2_rmse_A)/max(mean(valid_p0.id_pred_k2_rmse_A),eps); ...
    mean(negmin.Fd_oracle_rmse)-mean(neg0.Fd_oracle_rmse); ...
    sector_ratio;case_ratio;command_ratio;voltage_corr; ...
    mean(A2delta.axis_minus_common_id_rmse_A,'omitnan');oracle_improvement;eso_improvement];
scope=[repmat("six_condition_P1_vs_P0",3,1);"three_condition_id_-6_vs_0"; ...
    repmat("worst_case_cycle_association",4,1);"six_condition_alpha_pair"; ...
    "five_condition_offline_counterfactual";"five_condition_online_ESO"];
interpretation=["positive means saliency adds d prediction error"; ...
    "positive means saliency adds q prediction error"; ...
    "greater than one means IPMSM amplifies d residual"; ...
    "positive means negative id increases Fd residual"; ...
    repmat("association only; not a causal estimate",4,1); ...
    "negative means axis-specific improves d tracking"; ...
    "noncausal lower-bound improvement";"comparison baseline improvement"];
summary=table(statistic,value,scope,interpretation);
writetable(summary,fullfile(project.root,'results','summary','residual_rootcause_summary.csv'));
writetable(worst_trace,fullfile(project.root,'results','representative_traces', ...
    'worst_case_trace.csv'));
write_evidence(project,summary,scenario_name);
end

function ratio=event_ratio(error,event)
valid=isfinite(error); event=event&valid; stable=~event&valid;
if ~any(event)||~any(stable), ratio=NaN;
else, ratio=mean(abs(error(event)))/max(mean(abs(error(stable))),eps); end
end
function value=corr_safe(a,b)
valid=isfinite(a)&isfinite(b); if nnz(valid)<3, value=NaN; return; end
C=corrcoef(a(valid),b(valid)); value=C(1,2);
end
function values=mean_by_pole(T,required_count)
poles=unique(T.eso_pole); values=zeros(numel(poles),1);
for k=1:numel(poles)
    rows=T.eso_pole==poles(k);
    if nnz(rows)<required_count,values(k)=NaN;
    else,values(k)=mean(T.id_pred_k2_rmse_A(rows)+T.iq_pred_k2_rmse_A(rows),'omitnan');end
end
end
function write_evidence(project,T,scenario)
fid=fopen(fullfile(project.root,'diagnostics','residual_rootcause_evidence.md'), ...
    'w','n','UTF-8'); assert(fid>=0); cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'# Residual root-cause evidence\n\n- run_id: `%s`\n- worst case: `%s`\n\n', ...
    project.run_id,scenario);
fprintf(fid,['All transition ratios and correlations are associations, not causal ' ...
    'estimates. The interval oracle is noncausal and used only as a lower bound.\n\n']);
fprintf(fid,'| statistic | value | scope |\n|---|---:|---|\n');
for k=1:height(T), fprintf(fid,'| %s | %.9g | %s |\n',T.statistic(k),T.value(k),T.scope(k)); end
end
