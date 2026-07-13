function [summary,pointwise,gate] = experiment_A0_strict_P0_regression(project)
%EXPERIMENT_A0_STRICT_P0_REGRESSION Two independent full closed loops.

ref_project=project;
motor=project.motor; motor.Ld_H=motor.Ls_H; motor.Lq_H=motor.Ls_H;
motor.alpha_d=1/motor.Ls_H; motor.alpha_q=1/motor.Ls_H;
ref_project.paper=motor;
ref_project.assumptions.dc_bus_V=project.base.iter11_dc_bus_V;
ref_project.assumptions.inverter_disturbance_model= ...
    "paper_2us_average_deadtime_per_commutated_leg";
ref_project.assumptions.current_reference_ramp_s=.02;
ref_project.assumptions.estimator="fliess_join_2013_algebraic_integral";
new_project=ref_project;

conditions=[100 10;300 10;500 20];
summaries=cell(size(conditions,1),1); comparisons=cell(size(conditions,1),1);
for k=1:size(conditions,1)
    s=project.experiments(1);
    s.name=sprintf('A0_%drpm_%gA',conditions(k,1),conditions(k,2));
    s.speed_rpm=conditions(k,1); s.iq_ref_A=conditions(k,2); s.id_ref_A=0;
    s.reference_ramp_s=.02; s.simulation_time_s=.20; s.steady_window_start_s=.10;
    s.Jd_limit_A2=.2^2; s.Jq_limit_A2=.15^2;
    s.motor_model="P0"; s.alpha_mode="common_Ls";
    s.F_estimator="algebraic_iter11"; s.integration_step_s=Inf;
    ref=zhou_iter11_ref.sim.run_closed_loop("ICF_MPC",s,ref_project);
    candidate=zhou_ipmsm.sim.run_closed_loop("ICF_MPC",s,new_project);
    [comparisons{k},summaries{k}]=zhou_validation.compare_pointwise_runs( ...
        ref,candidate,s,project);
end
summary=vertcat(summaries{:}); pointwise=vertcat(comparisons{:});
gate=all(summary.pass_fail=="PASS");
directory=fullfile(project.root,'results','strict_regression',project.run_id);
writetable(pointwise,fullfile(directory,'pointwise_comparison.csv'));
writetable(summary,fullfile(project.root,'results','summary','p0_regression_summary.csv'));
write_diagnosis(project,pointwise,summary,gate);
end

function write_diagnosis(project,pointwise,summary,gate)
path_value=fullfile(project.root,'diagnostics','p0_regression_diagnosis.md');
fid=fopen(path_value,'w','n','UTF-8');
assert(fid>=0,'ZhouValidation:DiagnosisOpen','Cannot write A0 diagnosis.');
cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'# A0 strict P0 regression diagnosis\n\n');
fprintf(fid,'- run_id: `%s`\n- gate: **%s**\n\n',project.run_id,pass_text(gate));
if gate
    fprintf(fid,['Two independently executed closed loops matched every pre-registered ' ...
        'cycle-level gate. No threshold was changed.\n']);
    return;
end
fields={'case_match','vector_match','duration_structure_match', ...
    'id_error_A','iq_error_A','Fd_error','Fq_error','id_pred_k1_error_A', ...
    'iq_pred_k1_error_A','id_pred_k2_error_A','iq_pred_k2_error_A', ...
    'U3d_error_V','U3q_error_V'};
first_row=Inf; first_field="unknown";
for k=1:numel(fields)
    name=fields{k}; values=pointwise.(name);
    if islogical(values), bad=find(~values,1); else, bad=find(values~=0,1); end
    if ~isempty(bad) && bad<first_row, first_row=bad; first_field=string(name); end
end
if isfinite(first_row)
    fprintf(fid,'First difference: scenario `%s`, cycle %d, variable `%s`.\n', ...
        pointwise.scenario(first_row),pointwise.cycle_index(first_row),first_field);
else
    failed=summary(summary.pass_fail=="FAIL",:);
    fprintf(fid,'No exact-value difference was located; failed aggregate rows: %d.\n',height(failed));
end
fprintf(fid,'Producer functions: `zhou_iter11_ref.sim.run_closed_loop` and `zhou_ipmsm.sim.run_closed_loop`.\n');
end
function value=pass_text(condition)
if condition, value='PASS'; else, value='FAIL'; end
end
