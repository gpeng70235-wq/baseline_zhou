function [row,trace] = summarize_ipmsm_simulation(simulation,project,experiment_name)
%SUMMARIZE_IPMSM_SIMULATION Unified one-row schema and aligned trace.

if nargin<3, experiment_name="unspecified"; end
trace=zhou_validation.enrich_simulation_trace(simulation,project);
s=simulation.scenario; L=simulation.log; W=simulation.waveform;
steady=L.time_s>=s.steady_window_start_s;
assert(nnz(steady)>=10,'ZhouValidation:SteadyWindow','Steady window too short.');
ed=L.id_ref_A-L.id_A; eq=L.iq_ref_A-L.iq_A;
valid2=steady & isfinite(trace.plant_id_k2_A);
pred1d=L.id_pred_k1-[L.id_A(2:end);NaN];
pred1q=L.iq_pred_k1-[L.iq_A(2:end);NaN];
pred2d=L.id_pred_k2-trace.plant_id_k2_A;
pred2q=L.iq_pred_k2-trace.plant_iq_k2_A;

[thd,~,~]=zhou_validation.calculate_steady_state_thd(W, ...
    simulation.electrical_frequency_Hz,s.steady_window_start_s,W.time_s(end), ...
    "ia_A",project.assumptions.phase_current_thd_max_harmonic);
window=W.time_s>=thd.steady_window_start_s & W.time_s<thd.steady_window_end_s;
components=zhou_ipmsm.model.torque_components([W.id_A(window) W.iq_A(window)], ...
    simulation.plant_motor);
torque=components.total_Nm;
duration_s=max(nnz(steady)*project.base.Ts_s,eps);
controller_times=L.controller_time_s(steady);
case_total=max(nnz(steady),1);
Fvalid=steady & isfinite(trace.Fd_interval_oracle);
actual_d=trace.actual_exceedance_d_A(valid2);
actual_q=trace.actual_exceedance_q_A(valid2);
engineering=max(actual_d,actual_q)>0.1;
strict=max(actual_d,actual_q)>0.01;
numerical=max(actual_d,actual_q)>1e-9;
illegal=nnz(trace.illegal_command);
negative=nnz(trace.selected_min_duration_s < -project.thresholds.numeric_tolerance | ...
    trace.applied_min_duration_s < -project.thresholds.numeric_tolerance);
finite_ok=all(isfinite(L.id_A)) && all(isfinite(L.iq_A));
pass=finite_ok && illegal==0 && negative==0;

meta={string(project.run_id),string(project.timestamp),string(experiment_name), ...
    string(s.name),string(field_or(s,'motor_model',"P1")), ...
    simulation.plant_motor.Ld_H,simulation.plant_motor.Lq_H, ...
    simulation.plant_motor.Rs_Ohm,simulation.plant_motor.psi_f_Wb, ...
    s.speed_rpm,s.iq_ref_A,s.id_ref_A,string(field_or(s,'alpha_mode',"axis_specific")), ...
    string(field_or(s,'F_estimator',"algebraic_iter11")),project.base.Ts_s, ...
    field_or(s,'integration_step_s',Inf),thd.steady_window_start_s,thd.steady_window_end_s, ...
    string(pass_text(pass))};
names={'run_id','timestamp','experiment','scenario','motor_model','Ld','Lq','Rs', ...
    'psi_f','speed_rpm','iq_reference','id_reference','alpha_mode','F_estimator', ...
    'sampling_period','integration_step','steady_state_start','steady_state_end','pass_fail'};
row=cell2table(meta,'VariableNames',names);

row.id_rmse_A=rms_value(ed(steady)); row.iq_rmse_A=rms_value(eq(steady));
row.id_max_error_A=max(abs(ed(steady))); row.iq_max_error_A=max(abs(eq(steady)));
row.id_steady_bias_A=mean(ed(steady)); row.iq_steady_bias_A=mean(eq(steady));
row.id_pred_k1_rmse_A=rms_value(pred1d(steady & isfinite(pred1d)));
row.iq_pred_k1_rmse_A=rms_value(pred1q(steady & isfinite(pred1q)));
row.id_pred_k2_rmse_A=rms_value(pred2d(valid2));
row.iq_pred_k2_rmse_A=rms_value(pred2q(valid2));
row.max_prediction_error_A=max(abs([pred2d(valid2);pred2q(valid2)]));
row.Fd_oracle_rmse=rms_value(L.Fhat_d(Fvalid)-trace.Fd_interval_oracle(Fvalid));
row.Fq_oracle_rmse=rms_value(L.Fhat_q(Fvalid)-trace.Fq_interval_oracle(Fvalid));
row.numerical_violation_count=nnz(numerical);
row.strict_violation_count=nnz(strict);
row.engineering_violation_count=nnz(engineering);
row.engineering_violation_rate=mean_or_zero(engineering);
row.max_actual_exceedance_A=max([0;actual_d;actual_q]);
row.thd_percent=thd.thd_percent;
row.fundamental_rms_A=thd.fundamental_rms_A;
row.harmonic_rms_A=thd.harmonic_rms_A;
row.harmonic_power_A2=thd.harmonic_power_A2;
row.thd_electrical_cycles=thd.electrical_cycles;
row.thd_sample_count=thd.window_samples;
row.mean_torque_Nm=mean(torque); row.torque_std_Nm=std(torque);
row.torque_ripple_Nm=max(torque)-min(torque);
row.mean_magnet_torque_Nm=mean(components.magnet_Nm);
row.mean_reluctance_torque_Nm=mean(components.reluctance_Nm);
row.reluctance_torque_ratio=mean(components.reluctance_Nm)/max(abs(mean(torque)),eps);
row.switching_actions_per_sample=sum(L.switching_actions_applied(steady))/case_total;
row.effective_switching_frequency_Hz=sum(L.switching_actions_applied(steady))/(6*duration_s);
row.case1_ratio=nnz(L.case_selected(steady)==1)/case_total;
row.case2_ratio=nnz(L.case_selected(steady)==2)/case_total;
row.case3_ratio=nnz(L.case_selected(steady)==3)/case_total;
row.duration_min_s=min(trace.selected_min_duration_s(steady));
row.duration_mean_min_s=mean(trace.selected_min_duration_s(steady));
row.voltage_utilization_mean=mean(trace.voltage_utilization(steady));
row.voltage_utilization_max=max(trace.voltage_utilization(steady));
row.saturation_ratio=mean(trace.saturation_flag(steady));
row.illegal_commands=illegal; row.negative_durations=negative;
row.execution_mean_s=mean(controller_times); row.execution_p95_s=percentile95(controller_times);
end

function value=rms_value(x)
x=x(isfinite(x)); if isempty(x), value=NaN; else, value=sqrt(mean(x.^2)); end
end
function value=mean_or_zero(x)
if isempty(x), value=0; else, value=mean(x); end
end
function value=percentile95(x)
x=sort(x(:)); if isempty(x), value=NaN; else, value=x(max(1,ceil(.95*numel(x)))); end
end
function value=field_or(s,name,default_value)
if isfield(s,name), value=s.(name); else, value=default_value; end
end
function value=pass_text(pass)
if pass, value="PASS"; else, value="FAIL"; end
end
