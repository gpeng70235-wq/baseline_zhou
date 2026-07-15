function summary=summarize_simulation(simulation,project)
%SUMMARIZE_SIMULATION All requested steady-state/control metrics.

log=simulation.log;
s=simulation.scenario;
p=project.paper;
a=project.assumptions;
steady=log.time_s>=s.steady_window_start_s;
assert(nnz(steady)>10,'ZhouIPMSM:InvalidSteadyWindow','Steady window is too short.');
duration=nnz(steady)*p.Ts_s;
ed=log.id_ref_A(steady)-log.id_A(steady);
eq=log.iq_ref_A(steady)-log.iq_A(steady);

summary=struct();
summary.method=simulation.method;
summary.scenario=string(s.name);
summary.steady_start_s=s.steady_window_start_s;
summary.steady_end_s=log.time_s(end)+p.Ts_s;
summary.id_rmse_A=sqrt(mean(ed.^2));
summary.iq_rmse_A=sqrt(mean(eq.^2));
summary.total_current_rmse_A=sqrt(mean(ed.^2+eq.^2));
[summary.phase_current_thd_cycle_boundary_percent,~]=zhou_ipmsm.metrics.phase_thd( ...
    log.ia_A(steady),log.time_s(steady),simulation.electrical_frequency_Hz, ...
    a.phase_current_thd_max_harmonic);
wave=simulation.waveform;
steady_wave=wave.time_s>=s.steady_window_start_s & ...
    wave.time_s<summary.steady_end_s;
[summary.phase_current_thd_40_harmonic_percent,~]=zhou_ipmsm.metrics.phase_thd( ...
    wave.ia_A(steady_wave),wave.time_s(steady_wave), ...
    simulation.electrical_frequency_Hz,a.phase_current_thd_max_harmonic);
[summary.phase_current_thd_percent, ...
    summary.phase_current_fundamental_rms_A, ...
    summary.phase_current_distortion_rms_A]=zhou_ipmsm.metrics.phase_thd_total_rms( ...
    wave.ia_A(steady_wave),wave.time_s(steady_wave), ...
    simulation.electrical_frequency_Hz);
summary.phase_current_wideband_distortion_percent= ...
    summary.phase_current_thd_percent;
summary.torque_mean_Nm=mean(wave.torque_Nm(steady_wave));
summary.torque_peak_to_peak_Nm=range(wave.torque_Nm(steady_wave));
summary.average_switching_frequency_Hz= ...
    sum(log.switching_actions_applied(steady))/(6*duration);
summary.controller_time_mean_s=mean(log.controller_time_s(steady));
summary.controller_time_worst_s=max(log.controller_time_s(steady));
summary.iq_ripple_factor=std(log.iq_A(steady))/max(abs(mean(log.iq_A(steady))),eps);
summary.Cf=summary.phase_current_thd_percent* ...
    (summary.average_switching_frequency_Hz/1000);
summary.rectangle_area_mean_V2=mean(log.rectangle_area_V2(steady),'omitnan');
summary.Jd_mean=mean(log.Jd(steady)); summary.Jq_mean=mean(log.Jq(steady));
summary.Jd_max=max(log.Jd(steady)); summary.Jq_max=max(log.Jq(steady));
summary.predicted_d_violation_rate=mean(~log.constraint_d_ok(steady));
summary.predicted_q_violation_rate=mean(~log.constraint_q_ok(steady));
summary.case1_ratio=mean(log.case_selected(steady)==1);
summary.case2_ratio=mean(log.case_selected(steady)==2);
summary.case3_ratio=mean(log.case_selected(steady)==3);
summary.table_I_correction_rate=mean(log.table_I_correction(steady));
summary.table_I_fallback_rate=mean(log.table_I_fallback(steady));
summary.table_II_mismatch_rate=mean(log.table_II_mismatch(steady));
summary.phase_feasibility_flip_rate=mean(log.phase_feasibility_flip(steady));
summary.degenerate_single_point_rate=mean(log.degenerate_single_point(steady));
summary.illegal_command_count=nnz(~log.command_legal);
summary.numeric_negative_dwell_count=sum(log.tiny_negative_dwell_count);
summary.waveform_endpoint_max_residual_A=max(log.waveform_endpoint_residual_A);
summary.waveform_sample_period_s=a.waveform_sample_period_s;
summary.deadtime_delta_voltage_rms_V=sqrt(mean( ...
    log.deadtime_delta_d_V(steady).^2+log.deadtime_delta_q_V(steady).^2));
summary.deadtime_delta_voltage_max_V=max(hypot( ...
    log.deadtime_delta_d_V(steady),log.deadtime_delta_q_V(steady)));
summary.deadtime_adverse_events_mean=mean(log.deadtime_adverse_events(steady));

idx=find(steady & (1:height(log)).'<=height(log)-2);
actual_ed=log.id_ref_A(idx)-log.id_A(idx+2);
actual_eq=log.iq_ref_A(idx)-log.iq_A(idx+2);
summary.actual_k2_d_violation_rate=mean(actual_ed.^2>s.Jd_limit_A2+a.constraint_tolerance_A2);
summary.actual_k2_q_violation_rate=mean(actual_eq.^2>s.Jq_limit_A2+a.constraint_tolerance_A2);
summary.actual_k2_d_max_excess_A2=max([0;actual_ed.^2-s.Jd_limit_A2]);
summary.actual_k2_q_max_excess_A2=max([0;actual_eq.^2-s.Jq_limit_A2]);
end
