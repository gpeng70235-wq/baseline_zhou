function matrix = experiment_A4_parameter_sensitivity(project)
%EXPERIMENT_A4_PARAMETER_SENSITIVITY Plant-only, one-parameter-at-a-time scan.

all_s=project.experiments;
scenarios=[all_s(1),all_s(3),all_s(6)];
scenarios(2).name='300rpm_medium_15A'; scenarios(2).iq_ref_A=project.base.medium_current_A;
parameters=project.mismatches.sensitivity_parameters;
scales=project.mismatches.sensitivity_scales;
rows=cell(0,1); template=table();
for k=1:numel(scenarios)
    for parameter=parameters
        for scale=scales
            s=scenarios(k); s.motor_model="P1"; s.alpha_mode="axis_specific";
            s.F_estimator="algebraic_iter11"; s.simulation_time_s=.12;
            s.steady_window_start_s=.06;
            switch parameter
                case "Ld", s.plant_Ld_scale=scale;
                case "Lq", s.plant_Lq_scale=scale;
                case "Rs", s.plant_Rs_scale=scale;
                case "psi_f", s.plant_psi_f_scale=scale;
            end
            [row,~,~,ok]=zhou_validation.execute_ipmsm_case_safe( ...
                project,s,"parameter_sensitivity",false,template);
            if ok, template=row; end
            row.varied_parameter=parameter; row.parameter_scale=scale;
            row.scope_label="sensitivity_not_temperature_or_saturation";
            rows{end+1}=row; %#ok<AGROW>
        end
    end
end
matrix=vertcat(rows{:});
writetable(matrix,fullfile(project.root,'results','parameter_sensitivity',project.run_id,'metrics.csv'));
writetable(matrix,fullfile(project.root,'results','summary','parameter_sensitivity.csv'));
end
