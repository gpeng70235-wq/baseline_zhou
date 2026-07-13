function decision = resume_after_A4(run_id)
%RESUME_AFTER_A4 Development recovery for a run that completed A0-A4.
% Formal delivery still uses run_all_ipmsm_validation from a fresh run.

project=initialize_project(string(run_id));
[tests_pass,test_results]=run_unit_tests(project);
p0_summary=readtable(fullfile(project.root,'results','summary','p0_regression_summary.csv'),'TextType','string');
p0_pointwise=readtable(fullfile(project.root,'results','strict_regression',run_id,'pointwise_comparison.csv'),'TextType','string');
A1=readtable(fullfile(project.root,'results','summary','ipmsm_condition_matrix.csv'),'TextType','string');
A2=readtable(fullfile(project.root,'results','summary','alpha_mode_matrix.csv'),'TextType','string');
A2delta=readtable(fullfile(project.root,'results','summary','alpha_mode_delta.csv'),'TextType','string');
A3=readtable(fullfile(project.root,'results','summary','negative_id_matrix.csv'),'TextType','string');
A4=readtable(fullfile(project.root,'results','summary','parameter_sensitivity.csv'),'TextType','string');
alpha_assessment=assess_alpha(A2delta,project);
A5path=fullfile(project.root,'results','summary','parameter_stress.csv');
if isfile(A5path),A5=readtable(A5path,'TextType','string');else,A5=experiment_A5_parameter_stress(project);end
A6path=fullfile(project.root,'results','summary','F_estimator_comparison.csv');
if isfile(A6path),A6=readtable(A6path,'TextType','string');else,A6=experiment_A6_F_estimator_comparison(project);end
A7path=fullfile(project.root,'results','summary','residual_rootcause_summary.csv');
Wpath=fullfile(project.root,'results','representative_traces','worst_case_trace.csv');
if isfile(A7path)&&isfile(Wpath)
    A7=readtable(A7path,'TextType','string');worst_trace=readtable(Wpath,'TextType','string');
else
    [A7,worst_trace]=experiment_A7_residual_rootcause(project,A1,A2delta,A3,A6);
end
A8=experiment_A8_numerical_closure(project);
data=struct('tests_pass',tests_pass,'test_results',test_results,'p0_pass', ...
    all(p0_summary.pass_fail=="PASS"),'p0_summary',p0_summary, ...
    'p0_pointwise',p0_pointwise,'A1_gate',all(A1.pass_fail=="PASS"), ...
    'A1',A1,'A2',A2,'A2delta',A2delta,'alpha_assessment',alpha_assessment, ...
    'A3',A3,'A4',A4,'A5',A5,'A6',A6,'A7',A7,'worst_trace',worst_trace,'A8',A8);
save(fullfile(project.root,'results','summary',run_id,'validation_data.mat'),'data','-v7.3');
decision=zhou_validation.generate_validation_decision(project,data);
zhou_validation.generate_all_plots(project);
zhou_validation.generate_final_report(project,data,decision);
zhou_validation.generate_handoff_document(project,data,decision);
zhou_validation.generate_project_readme(project,decision);
zhou_validation.generate_inheritance_mapping(project);
zhou_validation.generate_manifests(project);
end
function a=assess_alpha(d,p)
valid=isfinite(d.axis_minus_common_id_rmse_A);
a.d_improvement_fraction=mean(d.axis_minus_common_id_rmse_A(valid)<0);
a.q_worsening_fraction=mean(d.axis_minus_common_iq_rmse_A(valid)>0);
a.thd_improvement_fraction=mean(d.axis_minus_common_thd_percent(valid)<0);
a.switching_increase_fraction=mean(d.axis_minus_common_switching_actions_per_sample(valid)>0);
a.constraint_improvement_fraction=mean(d.axis_minus_common_engineering_violation_rate(valid)<0);
a.valid_condition_count=nnz(valid);
a.cross_condition_effective=a.d_improvement_fraction>=p.thresholds.cross_condition_improvement_fraction && ...
    a.q_worsening_fraction<p.thresholds.cross_condition_improvement_fraction && nnz(valid)>=3;
end
