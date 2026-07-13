function decision = generate_validation_decision(project,data)
%GENERATE_VALIDATION_DECISION Select exactly one pre-registered A-F outcome.

A1=data.A1; p0=A1(A1.pair_role=="P0",:); p1=A1(A1.pair_role=="P1",:);
valid=p0.pass_fail=="PASS" & p1.pass_fail=="PASS";
ipmsm_amplifies=mean(p1.id_pred_k2_rmse_A+p1.iq_pred_k2_rmse_A) > ...
    (1+project.thresholds.significant_metric_relative_change)* ...
    mean(p0.id_pred_k2_rmse_A+p0.iq_pred_k2_rmse_A);
Fd_residual_ratio=NaN;Fq_residual_ratio=NaN;
if any(valid)
    Fd_residual_ratio=mean(p1.Fd_oracle_rmse(valid))/max(mean(p0.Fd_oracle_rmse(valid)),eps);
    Fq_residual_ratio=mean(p1.Fq_oracle_rmse(valid))/max(mean(p0.Fq_oracle_rmse(valid)),eps);
    ipmsm_amplifies=Fd_residual_ratio>1+project.thresholds.significant_metric_relative_change;
end
[negative_degradation,negative_thd_change,negative_ripple_change]=negative_effect(data.A3);
[most_sensitive,sensitivity_score]=parameter_sensitivity(data.A4);
[best_online,best_online_error,algebraic_error,oracle_error]=estimator_ranking(data.A6);
oracle_improvement=1-oracle_error/max(algebraic_error,eps);
online_improvement=1-best_online_error/max(algebraic_error,eps);
large_violations=any(p1.engineering_violation_rate>project.thresholds.max_engineering_violation_rate);
alpha_effective=logical(data.alpha_assessment.cross_condition_effective);
a8_pass=all(data.A8.numerical_gate=="PASS");

if ~data.tests_pass
    code="F"; title="证据不足";
    reason="至少一个核心单元测试失败，规则禁止形成理论结论。";
elseif ~data.p0_pass
    code="E"; title="当前移植不成立";
    reason="严格P0逐周期回归失败。";
elseif ~data.A1_gate
    code="E"; title="当前移植不成立";
    reason="严格P0已通过，但六工况合法性门因高速IPMSM非法Case失败。";
elseif alpha_effective && ~negative_degradation && ~large_violations && ...
        ~ipmsm_amplifies && a8_pass
    code="A"; title="允许直接进入MTPA";
    reason="P0、六工况、alpha、负id、约束、残余与数值门同时满足准入条件。";
elseif ipmsm_amplifies && oracle_improvement>=project.thresholds.significant_oracle_improvement && ...
        (~alpha_effective || oracle_improvement>online_improvement) && a8_pass
    code="B"; title="应先优化F估计";
    reason="IPMSM预测残余增加，非因果interval Oracle的降幅超过预注册阈值，alpha不能单独解释。";
elseif alpha_effective && oracle_improvement<project.thresholds.significant_oracle_improvement && ...
        a8_pass
    code="C"; title="应先优化输入增益";
    reason="两轴输入增益跨工况改善，而估计器替换的改善不足以主导解释。";
elseif ~ipmsm_amplifies && ~negative_degradation && ~large_violations && a8_pass
    code="D"; title="Zhou可作为IPMSM基线，但没有发现新研究问题";
    reason="移植稳定且没有工程意义上的新增劣化。";
else
    code="F"; title="证据不足";
    reason="现有证据不能唯一满足A-E任一完整条件集合。";
end

decision=struct('code',code,'title',title,'reason',reason, ...
    'allow_mtpa',code=="A",'alpha_effective',alpha_effective, ...
    'negative_degradation',negative_degradation, ...
    'negative_thd_relative_change',negative_thd_change, ...
    'negative_ripple_relative_change',negative_ripple_change, ...
    'most_sensitive_parameter',most_sensitive,'sensitivity_score',sensitivity_score, ...
    'best_online_estimator',best_online,'algebraic_prediction_error',algebraic_error, ...
    'best_online_prediction_error',best_online_error,'oracle_prediction_error',oracle_error, ...
    'oracle_improvement',oracle_improvement,'ipmsm_amplifies_residual',ipmsm_amplifies, ...
    'Fd_residual_ratio_P1_over_P0',Fd_residual_ratio, ...
    'Fq_residual_ratio_P1_over_P0',Fq_residual_ratio, ...
    'large_constraint_violations',large_violations,'numerical_gate_pass',a8_pass);
write_decision(project,decision);
end

function [degraded,thd_change,ripple_change]=negative_effect(T)
zero=T(T.id_reference==0 & T.pass_fail=="PASS",:);
low=T(T.id_reference==min(T.id_reference) & T.pass_fail=="PASS",:);
common=intersect(zero.scenario,low.scenario,'stable');thd=zeros(numel(common),1);ripple=thd;
for k=1:numel(common)
    z=zero(zero.scenario==common(k),:);l=low(low.scenario==common(k),:);
    thd(k)=(l.thd_percent(1)-z.thd_percent(1))/max(abs(z.thd_percent(1)),eps);
    ripple(k)=(l.torque_ripple_Nm(1)-z.torque_ripple_Nm(1))/max(abs(z.torque_ripple_Nm(1)),eps);
end
thd_change=mean(thd,'omitnan');ripple_change=mean(ripple,'omitnan');
degraded=thd_change>0.1 || ripple_change>0.1;
end
function [name,score]=parameter_sensitivity(T)
params=unique(T.varied_parameter,'stable'); scores=zeros(numel(params),1);
for k=1:numel(params)
    rows=T.varied_parameter==params(k); values=T.id_pred_k2_rmse_A(rows)+T.iq_pred_k2_rmse_A(rows);
    scores(k)=(max(values,[],'omitnan')-min(values,[],'omitnan'))/max(mean(values,'omitnan'),eps);
end
[score,idx]=max(scores);name=params(idx);
end
function [best,best_error,base_error,oracle_error]=estimator_ranking(T)
base=T(T.F_estimator=="algebraic_iter11" & T.pass_fail=="PASS",:);
oracle=T(T.F_estimator=="interval_F_oracle_offline" & T.pass_fail=="OFFLINE_ONLY",:);
base_error=mean(base.id_pred_k2_rmse_A+base.iq_pred_k2_rmse_A,'omitnan');
oracle_error=mean(oracle.id_pred_k2_rmse_A+oracle.iq_pred_k2_rmse_A,'omitnan');
eso=T(T.F_estimator=="basic_ESO" & T.pass_fail=="PASS",:);
best="algebraic_iter11";best_error=base_error;
required_scenarios=unique(base.scenario);
for pole=unique(eso.eso_pole).'
    rows=eso.eso_pole==pole;
    if numel(unique(eso.scenario(rows)))<numel(required_scenarios),continue;end
    value=mean(eso.id_pred_k2_rmse_A(rows)+eso.iq_pred_k2_rmse_A(rows),'omitnan');
    if value<best_error,best="basic_ESO_p"+string(pole);best_error=value;end
end
end
function write_decision(project,d)
fid=fopen(fullfile(project.root,'VALIDATION_DECISION.md'),'w','n','UTF-8');assert(fid>=0);
cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'# Validation decision\n\n## %s. %s\n\n',d.code,d.title);
fprintf(fid,'- run_id: `%s`\n- reason: %s\n- MTPA admission: **%s**\n', ...
    project.run_id,d.reason,yesno(d.allow_mtpa));
fprintf(fid,'- axis-specific cross-condition effective: **%s**\n',yesno(d.alpha_effective));
fprintf(fid,'- negative-id engineering degradation: **%s**\n',yesno(d.negative_degradation));
fprintf(fid,'- IPMSM residual amplification: **%s**\n',yesno(d.ipmsm_amplifies_residual));
fprintf(fid,'- P1/P0 Fd/Fq residual ratios: `%.6g / %.6g`\n', ...
    d.Fd_residual_ratio_P1_over_P0,d.Fq_residual_ratio_P1_over_P0);
fprintf(fid,'- numerical closure gate: **%s**\n\n',yesno(d.numerical_gate_pass));
fprintf(fid,['This file selects exactly one of the pre-registered A-F outcomes. ' ...
    'The offline interval Oracle is not an online control algorithm.\n']);
end
function value=yesno(x)
if x,value='YES';else,value='NO';end
end
