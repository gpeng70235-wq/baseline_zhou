function [summary,pointwise,gate]=run_p0_strict_regression(project)
%RUN_P0_STRICT_REGRESSION Three independent full-loop P0 comparisons.
ref_project=project;
motor=project.motor;motor.Ld_H=motor.Ls_H;motor.Lq_H=motor.Ls_H;
motor.alpha_d=1/motor.Ls_H;motor.alpha_q=1/motor.Ls_H;
ref_project.paper=motor;
ref_project.assumptions.dc_bus_V=84;
ref_project.assumptions.inverter_disturbance_model="paper_2us_average_deadtime_per_commutated_leg";
ref_project.assumptions.current_reference_ramp_s=.02;
ref_project.assumptions.estimator="fliess_join_2013_algebraic_integral";
new_project=ref_project;
conditions=[100 10;300 10;500 20];summaries=cell(3,1);comparisons=cell(3,1);
for k=1:3
    s=control_scenario(project);s.name=sprintf('P0_%drpm_%gA',conditions(k,1),conditions(k,2));
    s.speed_rpm=conditions(k,1);s.iq_ref_A=conditions(k,2);s.id_ref_A=0;
    s.reference_ramp_s=.02;s.simulation_time_s=.20;s.steady_window_start_s=.10;
    s.Jd_limit_A2=.2^2;s.Jq_limit_A2=.15^2;s.motor_model="P0";
    s.alpha_mode="common_Ls";s.F_estimator="algebraic_iter11";s.integration_step_s=Inf;
    ref=zhou_iter11_ref.sim.run_closed_loop("ICF_MPC",s,ref_project);
    candidate=zhou_ipmsm.sim.run_closed_loop("ICF_MPC",s,new_project);
    [comparisons{k},summaries{k}]=zhou_feasibility.compare_pointwise_runs( ...
        ref,candidate,s,project);
end
summary=vertcat(summaries{:});pointwise=vertcat(comparisons{:});gate=all(summary.pass_fail=="PASS");
summary=add_config(summary,84,.02,project);
pointwise=add_config(pointwise,84,.02,project);
dir_value=fullfile(project.root,'results','A0_frozen_regression',project.run_id);
writetable(summary,fullfile(dir_value,'P0_strict_regression_summary.csv'));
writetable(pointwise,fullfile(dir_value,'P0_strict_regression_pointwise.csv'));
end

function T=add_config(T,vdc,ramp,project)
n=height(T);T=addvars(T,repmat(vdc,n,1),repmat(project.base.voltage_vector_scale,n,1), ...
    repmat(vdc*project.base.voltage_vector_scale,n,1),repmat(ramp,n,1), ...
    repmat(project.base.Ts_s,n,1),repmat("P0",n,1),repmat(project.motor.Ls_H,n,1), ...
    repmat(project.motor.Ls_H,n,1),repmat("common_Ls",n,1), ...
    repmat("algebraic_iter11",n,1),'NewVariableNames',{'dc_bus_V', ...
    'voltage_vector_scale','active_vector_magnitude_V','reference_ramp_s', ...
    'sampling_period_s','motor_model','Ld_H','Lq_H','alpha_mode','F_estimator'});
end
