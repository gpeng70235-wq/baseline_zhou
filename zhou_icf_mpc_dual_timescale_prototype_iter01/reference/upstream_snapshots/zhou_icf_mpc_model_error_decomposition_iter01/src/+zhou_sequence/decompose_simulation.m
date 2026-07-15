function T=decompose_simulation(project,simulation)
%DECOMPOSE_SIMULATION Causal two-period avg/UL-sequence/plant-sequence audit.
L=simulation.trace;N=max(0,height(L)-2);assert(N>0,'ZhouSequence:ShortTrace');
Ts=project.paper.Ts_s;tol=project.assumptions.time_tolerance_s;
ul=zeros(N,2);plant=zeros(N,2);actual=[L.id_A(3:N+2),L.iq_A(3:N+2)];
avg=[L.id_pred_k2_A(1:N),L.iq_pred_k2_A(1:N)];
v1=nan(N,1);v2=v1;v3=v1;order=strings(N,1);prevend=v1;curstart=v1;curend=v1;
swinside=zeros(N,1);swcross=zeros(N,1);Ftrue=zeros(N,2);
for k=1:N
    pending=parse_command(L.applied_sequence_vector_ids(k),L.applied_sequence_durations_s(k));
    selected=parse_command(L.selected_sequence_vector_ids(k),L.selected_sequence_durations_s(k));
    F=[L.Fd_hat(k);L.Fq_hat(k)];alpha=[L.alpha_d(k);L.alpha_q(k)];
    iu=[L.measured_id_A(k);L.measured_iq_A(k)];theta=L.controller_theta_rad(k);omega=L.omega_e_rad_s(k);
    iu=ultralocal_period(iu,pending,F,alpha,simulation.vectors,theta,omega,0,Ts);
    iu=ultralocal_period(iu,selected,F,alpha,simulation.vectors,theta,omega,Ts,Ts);
    ul(k,:)=iu.';
    x=[L.id_A(k);L.iq_A(k);L.theta_e_rad(k)];
    [x,~,~]=zhou_ipmsm.model.integrate_command(x,pending,simulation.vectors,omega, ...
        simulation.plant_motor,Ts,tol,[0 0],project.sequence.decomposition_integration_step_s);
    [x,~,~]=zhou_ipmsm.model.integrate_command(x,selected,simulation.vectors,omega, ...
        simulation.plant_motor,Ts,tol,[0 0],project.sequence.decomposition_integration_step_s);
    plant(k,:)=x(1:2).';
    ids=positive_sequence(selected,tol);pids=positive_sequence(pending,tol);
    unique_ids=unique(ids,'stable');
    if numel(unique_ids)>0,v1(k)=unique_ids(1);end
    if numel(unique_ids)>1,v2(k)=unique_ids(2);end
    if numel(unique_ids)>2,v3(k)=unique_ids(3);end
    order(k)=strjoin(string(ids),'-');
    if ~isempty(pids),prevend(k)=pids(end);end
    if ~isempty(ids),curstart(k)=ids(1);curend(k)=ids(end);end
    if numel(ids)>1,swinside(k)=zhou_ipmsm.inverter.count_sequence_transitions(simulation.vectors.states(ids+1,:));end
    if ~isempty(pids)&&~isempty(ids),swcross(k)=sum(abs(simulation.vectors.states(pids(end)+1,:)-simulation.vectors.states(ids(1)+1,:)));end
    m=simulation.plant_motor;i=[L.id_A(k);L.iq_A(k)];
    Ftrue(k,:)=[-m.Rs_Ohm/m.Ld_H*i(1)+omega*m.Lq_H/m.Ld_H*i(2), ...
        -m.Rs_Ohm/m.Lq_H*i(2)-omega*m.Ld_H/m.Lq_H*i(1)-omega*m.psi_f_Wb/m.Lq_H];
end

ref=[L.id_ref_A(1:N),L.iq_ref_A(1:N)];
et=actual-avg;esu=ul-avg;emu=actual-ul;esp=plant-avg;emp=actual-plant;
Javg=(ref-avg).^2;Jul=(ref-ul).^2;Jplant=(ref-plant).^2;Jactual=(ref-actual).^2;
limits=[project.sequence.Jd_limit_A2,project.sequence.Jq_limit_A2];
pavg=Javg<=limits+project.assumptions.constraint_tolerance_A2;
pul=Jul<=limits+project.assumptions.constraint_tolerance_A2;
pplant=Jplant<=limits+project.assumptions.constraint_tolerance_A2;
pactual=Jactual<=limits+project.assumptions.constraint_tolerance_A2;
torque_ref=zhou_ipmsm.model.electromagnetic_torque(ref,simulation.plant_motor);

T=table(repmat(string(simulation.scenario.scenario_id),N,1),(1:N).',L.t_s(1:N), ...
    repmat(string(simulation.scenario.case_category),N,1), ...
    'VariableNames',{'case_id','sample_index','time_s','case_category'});
T.row_trace_index=(1:N).';T.range_class=repmat(string(simulation.scenario.range_class),N,1);
T.speed_rpm=L.speed_rpm(1:N);T.electrical_speed=L.omega_e_rad_s(1:N);T.electrical_angle=L.theta_e_rad(1:N);
T.id=L.id_A(1:N);T.iq=L.iq_A(1:N);T.id_ref=ref(:,1);T.iq_ref=ref(:,2);
T.torque_ref=torque_ref;T.torque_actual=L.torque_Nm(1:N);T.Vdc=L.dc_bus_V(1:N);
T.Ld_actual=repmat(simulation.plant_motor.Ld_H,N,1);T.Lq_actual=repmat(simulation.plant_motor.Lq_H,N,1);
T.Ld_controller=repmat(simulation.controller_motor.Ld_H,N,1);T.Lq_controller=repmat(simulation.controller_motor.Lq_H,N,1);
T.alpha_d=L.alpha_d(1:N);T.alpha_q=L.alpha_q(1:N);T.Fd=L.Fd_hat(1:N);T.Fq=L.Fq_hat(1:N);
T.Fd_true=Ftrue(:,1);T.Fq_true=Ftrue(:,2);T.delta_Fd=T.Fd-T.Fd_true;T.delta_Fq=T.Fq-T.Fq_true;
T.id_pred_avg=avg(:,1);T.iq_pred_avg=avg(:,2);T.id_pred_seq_ul=ul(:,1);T.iq_pred_seq_ul=ul(:,2);
T.id_pred_seq_plant=plant(:,1);T.iq_pred_seq_plant=plant(:,2);T.id_actual=actual(:,1);T.iq_actual=actual(:,2);
T.ed_total=et(:,1);T.eq_total=et(:,2);T.ed_sequence_ul=esu(:,1);T.eq_sequence_ul=esu(:,2);
T.ed_model_ul=emu(:,1);T.eq_model_ul=emu(:,2);T.ed_sequence_plant=esp(:,1);T.eq_sequence_plant=esp(:,2);
T.ed_model_plant=emp(:,1);T.eq_model_plant=emp(:,2);
T.Jd_avg=Javg(:,1);T.Jq_avg=Javg(:,2);T.Jd_seq_ul=Jul(:,1);T.Jq_seq_ul=Jul(:,2);
T.Jd_seq_plant=Jplant(:,1);T.Jq_seq_plant=Jplant(:,2);T.Jd_actual=Jactual(:,1);T.Jq_actual=Jactual(:,2);
T.avg_d_pass=pavg(:,1);T.avg_q_pass=pavg(:,2);T.seq_ul_d_pass=pul(:,1);T.seq_ul_q_pass=pul(:,2);
T.seq_plant_d_pass=pplant(:,1);T.seq_plant_q_pass=pplant(:,2);T.actual_d_pass=pactual(:,1);T.actual_q_pass=pactual(:,2);
T.false_safe_d=pavg(:,1)&~pactual(:,1);T.false_safe_q=pavg(:,2)&~pactual(:,2);
T.false_alarm_d=~pavg(:,1)&pactual(:,1);T.false_alarm_q=~pavg(:,2)&pactual(:,2);
T.false_safe_seq_ul_d=pul(:,1)&~pactual(:,1);T.false_safe_seq_ul_q=pul(:,2)&~pactual(:,2);
T.false_safe_seq_plant_d=pplant(:,1)&~pactual(:,1);T.false_safe_seq_plant_q=pplant(:,2)&~pactual(:,2);
T.mode=L.selected_case(1:N);T.vector_1=v1;T.vector_2=v2;T.vector_3=v3;T.vector_order_code=order;
T.duty_1=L.d1(1:N);T.duty_2=L.d2(1:N);T.duty_3=zeros(N,1);T.duty_zero=L.d0(1:N);T.duty_sum=L.duty_sum(1:N);
T.previous_end_vector=prevend;T.current_start_vector=curstart;T.current_end_vector=curend;
T.switching_count_inside_period=swinside;T.switching_count_cross_period=swcross;
T.original_voltage_alpha=L.original_reference_alpha_V(1:N);T.original_voltage_beta=L.original_reference_beta_V(1:N);
T.final_voltage_alpha=L.reference_alpha_V(1:N);T.final_voltage_beta=L.reference_beta_V(1:N);
T.voltage_utilization=L.voltage_utilization_ratio(1:N);T.distance_to_hexagon=L.hex_margin_V(1:N);
T.distance_to_Jd_boundary=sqrt(limits(1))-abs(ref(:,1)-avg(:,1));
T.distance_to_Jq_boundary=sqrt(limits(2))-abs(ref(:,2)-avg(:,2));
T.S2_triggered=logical(L.S2_used(1:N));T.saturation_triggered=T.voltage_utilization>=1-1e-12;
T.negative_duty_before_S2=min([L.original_d0(1:N),L.original_d1(1:N),L.original_d2(1:N)],[],2)<-project.assumptions.duty_tolerance;
T.invalid_duty_after_S2=~logical(L.selected_legal(1:N))|logical(L.negative_duration_selected(1:N));
T.pending_sequence_vector_ids=L.applied_sequence_vector_ids(1:N);T.pending_sequence_durations_s=L.applied_sequence_durations_s(1:N);
T.selected_sequence_vector_ids=L.selected_sequence_vector_ids(1:N);T.selected_sequence_durations_s=L.selected_sequence_durations_s(1:N);
T.original_sequence_vector_ids=L.original_sequence_vector_ids(1:N);T.original_sequence_durations_s=L.original_sequence_durations_s(1:N);
T.controller_execution_time_s=L.controller_execution_time_s(1:N);T.feasibility_layer_time_s=L.feasibility_layer_time_s(1:N);
T.duty_imbalance=max([T.duty_zero,T.duty_1,T.duty_2],[],2)-min([T.duty_zero,T.duty_1,T.duty_2],[],2);
T.closure_ul_d=T.ed_total-(T.ed_sequence_ul+T.ed_model_ul);T.closure_ul_q=T.eq_total-(T.eq_sequence_ul+T.eq_model_ul);
T.closure_plant_d=T.ed_total-(T.ed_sequence_plant+T.ed_model_plant);T.closure_plant_q=T.eq_total-(T.eq_sequence_plant+T.eq_model_plant);
T.ul_avg_gap_norm=hypot(T.ed_sequence_ul,T.eq_sequence_ul);T.plant_replay_gap_norm=hypot(T.ed_model_plant,T.eq_model_plant);

assert(max(abs([T.closure_ul_d;T.closure_ul_q;T.closure_plant_d;T.closure_plant_q]))<=project.sequence.closure_tolerance_A, ...
    'ZhouSequence:ClosureFailure','Residual identity did not close.');
assert(max(T.ul_avg_gap_norm)<=project.sequence.ultralocal_identity_tolerance_A, ...
    'ZhouSequence:UltralocalAlignmentFailure','UL sequence is inconsistent with controller average prediction.');
assert(max(T.plant_replay_gap_norm)<=project.sequence.plant_replay_tolerance_A, ...
    'ZhouSequence:PlantReplayFailure','Two-period plant replay does not reproduce actual k+2.');
end

function command=parse_command(ids_text,durations_text)
ids=str2double(split(string(ids_text),';')).';dur=str2double(split(string(durations_text),';')).';
assert(numel(ids)==numel(dur)&&all(isfinite(ids))&&all(isfinite(dur)),'ZhouSequence:SequenceParseFailure');
command=struct('sequence_vector_ids',ids,'sequence_durations_s',dur);
end
function i=ultralocal_period(i,command,F,alpha,vectors,theta,omega,offset,Ts)
elapsed=0;ids=command.sequence_vector_ids;dur=command.sequence_durations_s;
for j=1:numel(ids)
    dt=max(0,dur(j));
    if dt>0
        angle=theta+omega*(offset+elapsed+dt/2);
        u=zhou_ipmsm.math.park(vectors.ab_V(ids(j)+1,:),angle);
        i=i+dt*(F+alpha.*u);
    end
    elapsed=elapsed+dt;
end
assert(abs(elapsed-Ts)<=max(1e-13,100*eps(Ts)),'ZhouSequence:DwellSumFailure');
end
function ids=positive_sequence(command,tol)
ids=command.sequence_vector_ids(command.sequence_durations_s>tol);
end
