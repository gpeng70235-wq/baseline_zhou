function [matrix,gate] = experiment_A1_ipmsm_condition_matrix(project)
%EXPERIMENT_A1_IPMSM_CONDITION_MATRIX Six conditions, paired P0/P1 plants.

rows=cell(0,1); scenarios=project.experiments; template=table();
delta_names={'id_rmse_A','iq_rmse_A','id_pred_k2_rmse_A','iq_pred_k2_rmse_A', ...
    'thd_percent','torque_ripple_Nm','engineering_violation_rate', ...
    'voltage_utilization_mean','switching_actions_per_sample'};
for k=1:numel(scenarios)
    pair=cell(2,1);
    for model_index=1:2
        s=scenarios(k);
        if model_index==1, s.motor_model="P0"; else, s.motor_model="P1"; end
        s.alpha_mode="axis_specific"; s.F_estimator="algebraic_iter11";
        save_trace=(k==numel(scenarios) && model_index==2);
        [pair{model_index},~,~,ok]=zhou_validation.execute_ipmsm_case_safe( ...
            project,s,"condition_matrix",save_trace,template);
        if ok, template=pair{model_index}; end
        pair{model_index}.pair_role=string(s.motor_model);
        for f=1:numel(delta_names)
            pair{model_index}.("delta_"+string(delta_names{f}))=NaN;
        end
    end
    for f=1:numel(delta_names)
        name=delta_names{f};
        pair{2}.("delta_"+string(name))=pair{2}.(name)-pair{1}.(name);
    end
    rows(end+1:end+2)=pair; %#ok<AGROW>
end
matrix=vertcat(rows{:});
write_outputs(project,"condition_matrix","ipmsm_condition_matrix.csv",matrix);
gate=all(matrix.pass_fail=="PASS") && all(matrix.illegal_commands==0) && ...
    all(matrix.negative_durations==0);
end

function write_outputs(project,experiment,summary_name,value)
writetable(value,fullfile(project.root,'results',experiment,project.run_id,'metrics.csv'));
writetable(value,fullfile(project.root,'results','summary',summary_name));
end
