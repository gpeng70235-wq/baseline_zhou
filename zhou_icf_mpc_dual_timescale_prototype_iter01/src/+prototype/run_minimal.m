function result=run_minimal(project)
%RUN_MINIMAL Five representative cases, five methods, three repeats.
suite=prototype.run_suite(project,project.parameters.minimal_set,project.parameters.methods,3,"minimal",struct());
M=suite.method_metrics;B=M(M.method=="B0",:);P=M(M.method=="P",:);
C=suite.case_metrics(suite.case_metrics.repeat==1,:);
parameter_improvement=case_improved(C,"P08_opposed_20pct");known_improvement=case_improved(C,"C07_known_false_safe");
termination_match=termination_matches(C);
checks=["finite_and_legal";"termination_semantics";"aggregate_false_safe_nonincrease"; ...
    "false_alarm_temporary";"prediction_RMS_temporary";"parameter_case_improves"; ...
    "known_false_safe_improves";"alpha_not_long_at_boundary";"alpha_updates_nonzero"; ...
    "S2_actual_voltage_gate";"decision_not_permanent";"three_repeat_determinism"];
pass=[P.estimator_finite&&P.illegal_duration_count<=B.illegal_duration_count;termination_match; ...
    P.false_safe_rate<=B.false_safe_rate;P.false_alarm_rate<=.05;P.vector_rms_A<=1.5*B.vector_rms_A; ...
    parameter_improvement;known_improvement;P.alpha_boundary_hit_rate<.2;P.alpha_update_rate>0; ...
    P.s2_gate_rate>0;P.decision_gate_rate>0&&P.decision_gate_rate<1;all(suite.repeatability.pass)];
G=table(checks,pass,'VariableNames',{'check','pass'});writetable(G,fullfile(project.dirs.summary,'prototype_gate_results.csv'));
writetable(suite.case_metrics,fullfile(project.dirs.summary,'minimal_case_metrics.csv'));
result_pass=all(pass);
lines=["# Minimal Case Gate Report";"";"Result: **"+pass_label(result_pass)+"**.";""; ...
    "Five methods were run on nominal, opposed 20% mismatch, dynamic step, known false-safe and S2-boundary cases, with three deterministic repeats."; ...
    "Full 24-case execution is authorized only when every row in `prototype_gate_results.csv` passes."];
writelines(lines,fullfile(project.dirs.docs,'MINIMAL_CASE_GATE_REPORT.md'));
result=struct('pass',result_pass,'checks',G,'suite',suite);
end
function ok=case_improved(C,id)
b=C(C.case_id==id&C.method=="B0",:);p=C(C.case_id==id&C.method=="P",:);
ok=~isempty(b)&&~isempty(p)&&p.false_safe_rate<b.false_safe_rate;
end
function ok=termination_matches(C)
ok=true;for id=unique(C.case_id,'stable').'
    b=C(C.case_id==id&C.method=="B0",:);p=C(C.case_id==id&C.method=="P",:);
    ok=ok&&b.completed==p.completed&&(b.completed||b.trace_rows==p.trace_rows);
end
end
function s=pass_label(x),if x,s="PASS";else,s="FAIL";end,end
