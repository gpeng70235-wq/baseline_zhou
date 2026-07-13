function matrix = experiment_A5_parameter_stress(project)
%EXPERIMENT_A5_PARAMETER_STRESS Extreme stress only; not a real parameter range.

all_s=project.experiments;
scenarios=[all_s(1),all_s(3),all_s(6)];
scenarios(2).name='300rpm_medium_15A'; scenarios(2).iq_ref_A=project.base.medium_current_A;
cases={"Ld_0p5",[.5 1 1 1];"Ld_1p5",[1.5 1 1 1]; ...
    "Lq_0p5",[1 .5 1 1];"Lq_1p5",[1 1.5 1 1]; ...
    "Rs_0p5",[1 1 .5 1];"Rs_1p5",[1 1 1.5 1]; ...
    "psi_f_0p8",[1 1 1 .8];"psi_f_1p2",[1 1 1 1.2]; ...
    "combined",[.8 1.2 1.2 .9]};
rows=cell(0,1);
seed=scenarios(1);seed.motor_model="P1";seed.alpha_mode="axis_specific";
seed.F_estimator="algebraic_iter11";seed.simulation_time_s=.12;
seed.steady_window_start_s=.06;
[template,~,~]=zhou_validation.execute_ipmsm_case( ...
    project,seed,"parameter_stress",false);
template.error_identifier="";template.error_message="";
for k=1:numel(scenarios)
    for c=1:size(cases,1)
        s=scenarios(k); values=cases{c,2}; s.motor_model="P1";
        s.alpha_mode="axis_specific"; s.F_estimator="algebraic_iter11";
        s.simulation_time_s=.12; s.steady_window_start_s=.06;
        s.plant_Ld_scale=values(1); s.plant_Lq_scale=values(2);
        s.plant_Rs_scale=values(3); s.plant_psi_f_scale=values(4);
        [row,~,~,ok]=zhou_validation.execute_ipmsm_case_safe( ...
            project,s,"parameter_stress",false,template);
        if ok, template=row; end
        row.stress_case=string(cases{c,1});
        row.scope_label="stress_test_not_real_operating_range";
        rows{end+1}=row; %#ok<AGROW>
    end
end
matrix=vertcat(rows{:});
writetable(matrix,fullfile(project.root,'results','parameter_stress',project.run_id,'metrics.csv'));
writetable(matrix,fullfile(project.root,'results','summary','parameter_stress.csv'));
end
