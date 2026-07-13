function matrix = experiment_A6_F_estimator_comparison(project)
%EXPERIMENT_A6_F_ESTIMATOR_COMPARISON Same controller, estimator only changed.

all_s=project.experiments;
scenarios=[all_s(1),all_s(4),all_s(6),all_s(4),all_s(6)];
scenarios(4).name='300rpm_high_20A_negative_id'; scenarios(4).id_ref_A=-4;
scenarios(5).name='500rpm_20A_negative_id'; scenarios(5).id_ref_A=-4;
rows=cell(0,1); template=table();
for k=1:numel(scenarios)
    s=scenarios(k); s.motor_model="P1"; s.alpha_mode="axis_specific";
    s.F_estimator="algebraic_iter11"; s.eso_pole=NaN;
    [baseline,trace,~,base_ok]=zhou_validation.execute_ipmsm_case_safe( ...
        project,s,"estimator_comparison",true,template);
    if base_ok, template=baseline; end
    if base_ok
        baseline=add_estimator_fields(baseline,trace,NaN,"online_frozen_algebraic","","");
    else
        baseline=add_failed_estimator_fields(baseline,NaN,"online_frozen_algebraic_error");
    end
    rows{end+1}=baseline; %#ok<AGROW>

    oracle=baseline;
    oracle.F_estimator="interval_F_oracle_offline";
    oracle.control_path="offline_counterfactual_not_online";
    if base_ok
        oracle.pass_fail="OFFLINE_ONLY";
        valid=isfinite(trace.Fd_interval_oracle) & isfinite(trace.plant_id_k2_A);
        pred_d=trace.id_pred_k1_A+project.base.Ts_s*(trace.Fd_interval_oracle+ ...
            trace.alpha_d.*trace.U4d_V);
        pred_q=trace.iq_pred_k1_A+project.base.Ts_s*(trace.Fq_interval_oracle+ ...
            trace.alpha_q.*trace.U4q_V);
        oracle.id_pred_k2_rmse_A=rms_local(pred_d(valid)-trace.plant_id_k2_A(valid));
        oracle.iq_pred_k2_rmse_A=rms_local(pred_q(valid)-trace.plant_iq_k2_A(valid));
        oracle.max_prediction_error_A=max(abs([pred_d(valid)-trace.plant_id_k2_A(valid); ...
            pred_q(valid)-trace.plant_iq_k2_A(valid)]));
        oracle.Fd_oracle_rmse=0; oracle.Fq_oracle_rmse=0;
        oracle.noise_amplification_index=0; oracle.estimator_settling_s=NaN;
        oracle.event_peak_prediction_error_A=oracle.max_prediction_error_A;
        oracle.execution_mean_s=NaN; oracle.execution_p95_s=NaN; oracle.eso_pole=NaN;
    else
        oracle.pass_fail="FAIL";
    end
    rows{end+1}=oracle; %#ok<AGROW>

    for pole=project.estimators.eso_poles
        se=s; se.F_estimator="basic_ESO"; se.eso_pole=pole;
        [row,etrace,~,eso_ok]=zhou_validation.execute_ipmsm_case_safe( ...
                project,se,"estimator_comparison",true,template);
        if eso_ok
            row=add_estimator_fields(row,etrace,pole,"online_comparison_only","","");
        else
            row=add_failed_estimator_fields(row,pole,"online_comparison_error");
        end
        rows{end+1}=row; %#ok<AGROW>
    end
end

function row=add_failed_estimator_fields(row,pole,path)
row.eso_pole=pole;row.control_path=string(path);
row.noise_amplification_index=NaN;row.estimator_settling_s=NaN;
row.event_peak_prediction_error_A=NaN;
end
matrix=vertcat(rows{:});
writetable(matrix,fullfile(project.root,'results','estimator_comparison', ...
    project.run_id,'metrics.csv'));
writetable(matrix,fullfile(project.root,'results','summary','F_estimator_comparison.csv'));
end

function row=add_estimator_fields(row,trace,pole,path,error_id,error_message)
row.eso_pole=pole; row.control_path=string(path);
row.error_identifier=string(error_id); row.error_message=string(error_message);
valid=isfinite(trace.Fd_interval_oracle);
F=[trace.Fd_estimated(valid) trace.Fq_estimated(valid)];
i=[trace.id_A(valid) trace.iq_A(valid)];
row.noise_amplification_index=rms_local(diff(F(:)))/max(rms_local(diff(i(:))),eps);
error=hypot(trace.Fd_estimated-trace.Fd_interval_oracle, ...
    trace.Fq_estimated-trace.Fq_interval_oracle);
row.estimator_settling_s=settling_time(trace.time_s,error);
events=trace.command_transition|trace.sector_transition|trace.case_transition;
event_error=hypot(trace.prediction_error_d_A(events),trace.prediction_error_q_A(events));
if isempty(event_error), row.event_peak_prediction_error_A=0;
else, row.event_peak_prediction_error_A=max(event_error,[],'omitnan'); end
end
function value=settling_time(time,error)
valid=isfinite(error); time=time(valid); error=error(valid);
if isempty(error), value=NaN; return; end
tail=error(max(1,floor(.8*numel(error))):end);
limit=max(1.1*rms_local(tail),eps); value=NaN;
for k=1:max(1,numel(error)-4)
    if all(error(k:min(k+4,end))<=limit), value=time(k); return; end
end
end
function value=rms_local(x)
x=x(isfinite(x)); if isempty(x), value=NaN; else, value=sqrt(mean(x.^2)); end
end
function write_error(project,s,e)
path_value=fullfile(project.root,'diagnostics','runtime_errors', ...
    sprintf('%s_A6_%s_%s.txt',project.run_id,s.name,string(s.eso_pole)));
fid=fopen(path_value,'w','n','UTF-8'); if fid<0, return; end
cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n%s\n\n%s',e.identifier,e.message,getReport(e,'extended'));
end
