function [matrix,delta,assessment] = experiment_A2_alpha_mode_matrix(project)
%EXPERIMENT_A2_ALPHA_MODE_MATRIX Pre-registered common versus axis alpha.

rows=cell(0,1); scenarios=project.experiments; template=table();
for k=1:numel(scenarios)
    for mode=["common_Ls" "axis_specific"]
        s=scenarios(k); s.motor_model="P1"; s.alpha_mode=mode;
        s.F_estimator="algebraic_iter11";
        [row,~,~,ok]=zhou_validation.execute_ipmsm_case_safe( ...
            project,s,"alpha_matrix",false,template);
        if ok, template=row; end
        rows{end+1}=row; %#ok<AGROW>
    end
end
matrix=vertcat(rows{:});
delta_rows=cell(numel(scenarios),1);
metrics={'id_rmse_A','iq_rmse_A','thd_percent','switching_actions_per_sample', ...
    'engineering_violation_rate','voltage_utilization_mean'};
for k=1:numel(scenarios)
    common=matrix(2*k-1,:); axis=matrix(2*k,:);
    d=table(string(scenarios(k).name),scenarios(k).speed_rpm, ...
        'VariableNames',{'scenario','speed_rpm'});
    for f=1:numel(metrics)
        name=metrics{f}; d.("axis_minus_common_"+string(name))=axis.(name)-common.(name);
    end
    delta_rows{k}=d;
end
delta=vertcat(delta_rows{:});
assessment=struct();
valid=isfinite(delta.axis_minus_common_id_rmse_A);
assessment.d_improvement_fraction=mean(delta.axis_minus_common_id_rmse_A(valid)<0);
assessment.q_worsening_fraction=mean(delta.axis_minus_common_iq_rmse_A(valid)>0);
assessment.thd_improvement_fraction=mean(delta.axis_minus_common_thd_percent(valid)<0);
assessment.switching_increase_fraction=mean(delta.axis_minus_common_switching_actions_per_sample(valid)>0);
assessment.constraint_improvement_fraction=mean(delta.axis_minus_common_engineering_violation_rate(valid)<0);
assessment.valid_condition_count=nnz(valid);
assessment.cross_condition_effective=assessment.d_improvement_fraction>= ...
    project.thresholds.cross_condition_improvement_fraction && ...
    assessment.q_worsening_fraction<project.thresholds.cross_condition_improvement_fraction && nnz(valid)>=3;
writetable(matrix,fullfile(project.root,'results','alpha_matrix',project.run_id,'metrics.csv'));
writetable(matrix,fullfile(project.root,'results','summary','alpha_mode_matrix.csv'));
writetable(delta,fullfile(project.root,'results','summary','alpha_mode_delta.csv'));
end
