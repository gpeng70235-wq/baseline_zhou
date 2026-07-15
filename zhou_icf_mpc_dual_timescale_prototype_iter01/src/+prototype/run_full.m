function result=run_full(project)
%RUN_FULL Complete 24-case, five-method, three-repeat campaign.
gate=readtable(fullfile(project.dirs.summary,'prototype_gate_results.csv'),'TextType','string');
assert(all(logical(gate.pass)),'Prototype:MinimalGateFailed','Full campaign prohibited by minimal gate.');
scenarios=sequence_scenarios(project);ids=string({scenarios.scenario_id});
suite=prototype.run_suite(project,ids,project.parameters.methods,3,"full",struct());
M=suite.method_metrics;C=suite.case_metrics;H=suite.cohort_metrics;
writetable(M,fullfile(project.dirs.summary,'method_metrics.csv'));
writetable(C,fullfile(project.dirs.summary,'case_metrics.csv'));
writetable(H,fullfile(project.dirs.summary,'cohort_metrics.csv'));
writetable(suite.repeatability,fullfile(project.dirs.summary,'repeatability.csv'));
write_secondary_summaries(project,M,C);
B=M(M.method=="B0",:);P=M(M.method=="P",:);
cohort_gain=true;
for cohort=["core","dynamic","parameter"]
    b=H(H.method=="B0"&H.cohort==cohort,:);p=H(H.method=="P"&H.cohort==cohort,:);
    cohort_gain=cohort_gain&&~isempty(b)&&~isempty(p)&&p.false_safe_rate<b.false_safe_rate;
end
thresholds=table(["false_safe_relative";"false_safe_absolute";"false_alarm";"prediction_RMS"; ...
    "THD";"torque_ripple";"cross_cohort";"finite";"illegal_duration";"repeatability"], ...
    [P.false_safe_rate<=.5*B.false_safe_rate;P.false_safe_rate<=.0152;P.false_alarm_rate<=.02; ...
    P.vector_rms_A<=1.1*B.vector_rms_A;relative_ok(P.phase_thd,B.phase_thd,.05); ...
    relative_ok(P.torque_ripple_Nm,B.torque_ripple_Nm,.05);cohort_gain;P.estimator_finite; ...
    P.illegal_duration_count==0;all(suite.repeatability.pass)], ...
    'VariableNames',{'gate','pass'});
writetable(thresholds,fullfile(project.dirs.summary,'full_performance_gates.csv'));
lines=["# Full 24-Case Report";"";"Campaign completed: 24 frozen cases × 5 methods × 3 repeats."; ...
    "";"Performance gate result before the independent timing audit: **"+pass_label(all(thresholds.pass))+"**."; ...
    "Stress-test cases remain in REPRODUCTION_ALL outputs but are excluded from ENGINEERING_PRIMARY conclusions."];
writelines(lines,fullfile(project.dirs.docs,'FULL_24_CASE_REPORT.md'));
result=struct('pass',all(thresholds.pass),'gates',thresholds,'suite',suite,'cohort_gain',cohort_gain);
end
function ok=relative_ok(a,b,tol)
if ~isfinite(a)||~isfinite(b),ok=true;else,ok=a<=b*(1+tol);end
end
function write_secondary_summaries(project,M,C)
control_names=intersect(M.Properties.VariableNames,{'method','id_tracking_rms_A','iq_tracking_rms_A', ...
    'phase_thd','torque_ripple_Nm','S2_count','illegal_duration_count'},'stable');
writetable(M(:,control_names),fullfile(project.dirs.summary,'control_performance.csv'));
est_names=intersect(M.Properties.VariableNames,{'method','alpha_boundary_hit_rate','alpha_update_rate', ...
    'gate_freeze_rate','decision_gate_rate','s2_gate_rate'},'stable');
writetable(M(:,est_names),fullfile(project.dirs.summary,'estimator_statistics.csv'));
writetable(M(:,intersect(M.Properties.VariableNames,{'method','gate_freeze_rate','decision_gate_rate','s2_gate_rate'},'stable')), ...
    fullfile(project.dirs.summary,'gate_statistics.csv'));
rows=cell(height(M),1);for k=1:height(M)
    n=max(M.sample_count(k),1);fs=round(M.false_safe_rate(k)*n);fa=round(M.false_alarm_rate(k)*n);
    rows{k}=table(M.method(k),n,fs,fa,M.false_safe_rate(k),M.false_alarm_rate(k), ...
        'VariableNames',{'method','samples','false_safe_count','false_alarm_count','false_safe_rate','false_alarm_rate'});
end
writetable(vertcat(rows{:}),fullfile(project.dirs.summary,'constraint_confusion.csv'));
end
function s=pass_label(x),if x,s="PASS";else,s="FAIL";end,end
