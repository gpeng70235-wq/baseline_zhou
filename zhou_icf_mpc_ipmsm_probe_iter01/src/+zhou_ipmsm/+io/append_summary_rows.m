function summary_rows = append_summary_rows(cfg, run_id, experiment_name, metric_rows, path)
%APPEND_SUMMARY_ROWS Add required run metadata to every experimental condition.
summary_rows = table();
for row_index = 1:height(metric_rows)
    alpha_mode = string(cfg.alpha_mode);
    id_reference = cfg.id_ref;
    if ismember('alpha_mode',metric_rows.Properties.VariableNames)
        alpha_mode = string(metric_rows.alpha_mode(row_index));
    end
    if ismember('id_reference',metric_rows.Properties.VariableNames)
        id_reference = metric_rows.id_reference(row_index);
    end
    row = table(string(run_id),string(experiment_name),string(cfg.parameter_set), ...
        string(cfg.motor.type),alpha_mode,id_reference,cfg.speed_rpm,cfg.iq_ref, ...
        string(datetime('now','Format','yyyy-MM-dd''T''HH:mm:ss.SSS')), ...
        'VariableNames',{'run_id','experiment_name','parameter_set','motor_type', ...
        'alpha_mode','id_reference','speed','current','timestamp'});
    names = metric_rows.Properties.VariableNames;
    for column_index = 1:numel(names)
        name = names{column_index};
        if ~ismember(name,row.Properties.VariableNames) && ...
                ~ismember(name,{'alpha_mode','id_reference'})
            row.(name) = metric_rows.(name)(row_index,:);
        end
    end
    summary_rows = [summary_rows;row]; %#ok<AGROW>
end
zhou_ipmsm.io.write_result_table(summary_rows,path,true);
end
