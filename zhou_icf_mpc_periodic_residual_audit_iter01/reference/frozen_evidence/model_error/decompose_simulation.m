function [T,audit]=decompose_simulation(project,simulation)
%DECOMPOSE_SIMULATION Build the strict k-to-k+2 P0--P5 predictor ladder.
% All oracle substitutions are offline diagnostics and never feed the loop.
L=simulation.trace;N=max(0,height(L)-2);assert(N>0,'ZhouModelError:ShortTrace');
Ts=project.paper.Ts_s;names=project.model_error.predictor_names;M=numel(names);
assert(all(abs([project.model_error.Jd_limit_A2,project.model_error.Jq_limit_A2]-.16)<=eps(.16)), ...
    'ZhouModelError:ConstraintDrift');
assert(max(abs(L.measured_id_A(1:N)-L.id_A(1:N)))<=1e-12&& ...
    max(abs(L.measured_iq_A(1:N)-L.iq_A(1:N)))<=1e-12, ...
    'ZhouModelError:MeasurementContamination','Main attribution requires measured=actual.');
assert(max(abs(wrap_pi(L.controller_theta_rad(1:N)-L.theta_e_rad(1:N))))<=1e-12, ...
    'ZhouModelError:FrameContamination','Main attribution requires controller theta=actual theta.');

pred=nan(N,2,M);Fprev0=nan(N,2);FprevA=nan(N,2);Finst=nan(N,2);
Fcur0=nan(N,2);FcurA=nan(N,2);p3aFixed=nan(N,2);p3cFixed=nan(N,2);
uPending=nan(N,2);uSelected=nan(N,2);uPrev=nan(N,2);
p0gap=zeros(N,1);p5gap=zeros(N,1);prevClosure=nan(N,1);curClosure=nan(N,1);
p2cFirst=nan(N,1);p4Identity=nan(N,1);commandCarry=zeros(N,1);
m=simulation.plant_motor;alphaStar=[1/m.Ld_H;1/m.Lq_H];

% Sign/unit check against the frozen plant derivative at zero voltage.
xcheck=[L.id_A(1);L.iq_A(1);L.theta_e_rad(1)];
dcheck=zhou_ipmsm.model.pmsm_derivative(xcheck,[0 0],L.omega_e_rad_s(1),m,[0 0]);
fcheck=physical_F(xcheck(1:2),L.omega_e_rad_s(1),m);
assert(max(abs(dcheck(1:2)-fcheck))<=1e-11,'ZhouModelError:PhysicalFSign');

for k=1:N
    pending=parse_command(L.applied_sequence_vector_ids(k),L.applied_sequence_durations_s(k));
    selected=parse_command(L.selected_sequence_vector_ids(k),L.selected_sequence_durations_s(k));
    validate_command(pending,Ts,project.assumptions.time_tolerance_s);
    validate_command(selected,Ts,project.assumptions.time_tolerance_s);
    [nextAppliedIds,nextAppliedDur]=deal(L.applied_sequence_vector_ids(k+1),L.applied_sequence_durations_s(k+1));
    commandCarry(k)=same_command(selected,nextAppliedIds,nextAppliedDur,Ts);
    assert(commandCarry(k),'ZhouModelError:SelectedAppliedMisalignment', ...
        'selected(k) does not equal applied(k+1) at trace row %d.',k);

    thetaC=L.controller_theta_rad(k);thetaA=L.theta_e_rad(k);omega=L.omega_e_rad_s(k);
    uP=equivalent_voltage(pending,simulation.vectors,thetaC,omega,0,Ts);
    uS=equivalent_voltage(selected,simulation.vectors,thetaC,omega,1,Ts);
    uPa=equivalent_voltage(pending,simulation.vectors,thetaA,omega,0,Ts);
    uPending(k,:)=uP.';uSelected(k,:)=uS.';
    assert(norm(uP-uPa)<=1e-10,'ZhouModelError:ControllerPlantFrameMismatch');
    i0m=[L.measured_id_A(k);L.measured_iq_A(k)];i0=[L.id_A(k);L.iq_A(k)];
    i1actual=[L.id_A(k+1);L.iq_A(k+1)];actual=[L.id_A(k+2);L.iq_A(k+2)];
    F0=[L.Fd_hat(k);L.Fq_hat(k)];a0=[L.alpha_d(k);L.alpha_q(k)];
    Finst(k,:)=physical_F(i0,omega,m).';

    if k>1
        prev=parse_command(L.applied_sequence_vector_ids(k-1),L.applied_sequence_durations_s(k-1));
        up=equivalent_voltage(prev,simulation.vectors,L.theta_e_rad(k-1),L.omega_e_rad_s(k-1),0,Ts);
        uPrev(k,:)=up.';
        delta=(i0-[L.id_A(k-1);L.iq_A(k-1)])/Ts;
        Fprev0(k,:)=(delta-a0.*up).';FprevA(k,:)=(delta-alphaStar.*up).';
        prevClosure(k)=norm([L.id_A(k-1);L.iq_A(k-1)]+Ts*(Fprev0(k,:).'+a0.*up)-i0);
    end
    deltaCur=(i1actual-i0)/Ts;
    Fcur0(k,:)=(deltaCur-a0.*uPa).';FcurA(k,:)=(deltaCur-alphaStar.*uPa).';
    curClosure(k)=norm(i0+Ts*(Fcur0(k,:).'+a0.*uPa)-i1actual);

    pred(k,:,1)=two_period(i0m,F0,a0,uP,uS,Ts).';
    pred(k,:,2)=two_period(i0m,F0,alphaStar,uP,uS,Ts).';
    if k>1
        pred(k,:,3)=two_period(i0,Fprev0(k,:).',a0,uP,uS,Ts).';
        pred(k,:,6)=two_period(i0,FprevA(k,:).',alphaStar,uP,uS,Ts).';
        p3aFixed(k,:)=two_period(i0,Fprev0(k,:).',alphaStar,uP,uS,Ts).';
    end
    pred(k,:,4)=two_period(i0,Finst(k,:).',a0,uP,uS,Ts).';
    pred(k,:,5)=two_period(i0,Fcur0(k,:).',a0,uP,uS,Ts).';
    pred(k,:,7)=two_period(i0,Finst(k,:).',alphaStar,uP,uS,Ts).';
    pred(k,:,8)=two_period(i0,FcurA(k,:).',alphaStar,uP,uS,Ts).';
    p3cFixed(k,:)=two_period(i0,Fcur0(k,:).',alphaStar,uP,uS,Ts).';

    i1e=i0+Ts*(Finst(k,:).'+alphaStar.*uP);
    f1=physical_F(i1e,omega,m);
    pred(k,:,9)=(i1e+Ts*(f1+alphaStar.*uS)).';
    p4Identity(k)=norm(pred(k,:,9).'-pred(k,:,7).'-Ts*(f1-Finst(k,:).'));

    x=[i0;thetaA];
    [x,~,~]=zhou_ipmsm.model.integrate_command(x,pending,simulation.vectors,omega,m,Ts, ...
        project.assumptions.time_tolerance_s,[0 0],project.model_error.integration_step_s);
    [x,~,~]=zhou_ipmsm.model.integrate_command(x,selected,simulation.vectors,omega,m,Ts, ...
        project.assumptions.time_tolerance_s,[0 0],project.model_error.integration_step_s);
    pred(k,:,10)=x(1:2).';

    p0gap(k)=norm(pred(k,:,1).'-[L.id_pred_k2_A(k);L.iq_pred_k2_A(k)]);
    p5gap(k)=norm(pred(k,:,10).'-actual);
    p2cFirst(k)=norm(i0+Ts*(Fcur0(k,:).'+a0.*uP)-i1actual);
end

assert(max(p0gap)<=project.model_error.predictor_tolerance_A,'ZhouModelError:P0Reproduction');
assert(max(p5gap)<=project.model_error.plant_replay_tolerance_A,'ZhouModelError:P5Replay');
assert(max(prevClosure,[],'omitnan')<=1e-12&&max(curClosure)<=1e-12,'ZhouModelError:FOracleClosure');
assert(max(p2cFirst)<=1e-12,'ZhouModelError:P2cFirstStepClosure');
assert(max(p4Identity)<=2e-12,'ZhouModelError:P4Identity');

actual=[L.id_A(3:N+2),L.iq_A(3:N+2)];ref=[L.id_ref_A(1:N),L.iq_ref_A(1:N)];
E=nan(N,2,M);J=E;pass=false(N,2,M);fs=false(N,M);fa=false(N,M);
actualJ=(ref-actual).^2;actualPass=actualJ<=[.16,.16]+project.assumptions.constraint_tolerance_A2;
for j=1:M
    E(:,:,j)=actual-pred(:,:,j);J(:,:,j)=(ref-pred(:,:,j)).^2;
    pass(:,:,j)=J(:,:,j)<=[.16,.16]+project.assumptions.constraint_tolerance_A2;
    fs(:,j)=all(pass(:,:,j),2)&~all(actualPass,2);
    fa(:,j)=~all(pass(:,:,j),2)&all(actualPass,2);
end

T=table(repmat(string(simulation.scenario.scenario_id),N,1), ...
    repmat(string(simulation.scenario.case_category),N,1),(1:N).',L.t_s(1:N), ...
    'VariableNames',{'case_id','case_category','sample_index','time_s'});
T.range_class=repmat(string(simulation.scenario.range_class),N,1);
T.row_trace_index=(1:N).';T.speed_rpm=L.speed_rpm(1:N);T.electrical_speed=L.omega_e_rad_s(1:N);
T.electrical_angle=L.theta_e_rad(1:N);T.id=L.id_A(1:N);T.iq=L.iq_A(1:N);
T.id_actual=actual(:,1);T.iq_actual=actual(:,2);T.id_ref=ref(:,1);T.iq_ref=ref(:,2);
T.torque_ref=zhou_ipmsm.model.electromagnetic_torque(ref,m);T.torque_actual=L.torque_Nm(1:N);T.Vdc=L.dc_bus_V(1:N);
T.Ld_actual=repmat(m.Ld_H,N,1);T.Lq_actual=repmat(m.Lq_H,N,1);
T.Ld_controller=repmat(simulation.controller_motor.Ld_H,N,1);T.Lq_controller=repmat(simulation.controller_motor.Lq_H,N,1);
T.Rs_actual=repmat(m.Rs_Ohm,N,1);T.Rs_controller=repmat(simulation.controller_motor.Rs_Ohm,N,1);
T.psi_actual=repmat(m.psi_f_Wb,N,1);T.psi_controller=repmat(simulation.controller_motor.psi_f_Wb,N,1);
T.Fd_original=L.Fd_hat(1:N);T.Fq_original=L.Fq_hat(1:N);
T.Fd_oracle_previous=Fprev0(:,1);T.Fq_oracle_previous=Fprev0(:,2);
T.Fd_oracle_previous_alpha_oracle=FprevA(:,1);T.Fq_oracle_previous_alpha_oracle=FprevA(:,2);
T.Fd_oracle_instant=Finst(:,1);T.Fq_oracle_instant=Finst(:,2);
T.Fd_oracle_acausal=Fcur0(:,1);T.Fq_oracle_acausal=Fcur0(:,2);
T.Fd_oracle_acausal_alpha_oracle=FcurA(:,1);T.Fq_oracle_acausal_alpha_oracle=FcurA(:,2);
T.delta_Fd=T.Fd_original-T.Fd_oracle_instant;T.delta_Fq=T.Fq_original-T.Fq_oracle_instant;
T.delta_Fd_sample=[NaN;diff(T.Fd_original)];T.delta_Fq_sample=[NaN;diff(T.Fq_original)];
T.alpha_d_original=L.alpha_d(1:N);T.alpha_q_original=L.alpha_q(1:N);
T.alpha_d_oracle=repmat(alphaStar(1),N,1);T.alpha_q_oracle=repmat(alphaStar(2),N,1);
T.alpha_d_error=T.alpha_d_original-T.alpha_d_oracle;T.alpha_q_error=T.alpha_q_original-T.alpha_q_oracle;
for j=1:M
    n=char(names(j));T.("id_pred_"+n)=pred(:,1,j);T.("iq_pred_"+n)=pred(:,2,j);
    T.("ed_"+n)=E(:,1,j);T.("eq_"+n)=E(:,2,j);
    T.("Jd_"+n)=J(:,1,j);T.("Jq_"+n)=J(:,2,j);
    T.("false_safe_"+n)=fs(:,j);T.("false_alarm_"+n)=fa(:,j);
    T.("predicted_pass_"+n)=all(pass(:,:,j),2);
end
T.id_pred_P3a_fixed_gauge=p3aFixed(:,1);T.iq_pred_P3a_fixed_gauge=p3aFixed(:,2);
T.id_pred_P3c_fixed_gauge=p3cFixed(:,1);T.iq_pred_P3c_fixed_gauge=p3cFixed(:,2);
T.Jd_actual=actualJ(:,1);T.Jq_actual=actualJ(:,2);T.actual_joint_pass=all(actualPass,2);
T.mode=L.selected_case(1:N);T.vector_mode=physical_mode_column(L.selected_sequence_vector_ids(1:N),L.selected_sequence_durations_s(1:N),Ts);
T.vector_order_code=L.selected_sequence_vector_ids(1:N);T.S2_triggered=logical(L.S2_used(1:N));
T.voltage_utilization=L.voltage_utilization_ratio(1:N);
T.distance_to_Jd_boundary=sqrt(.16)-abs(ref(:,1)-pred(:,1,1));
T.distance_to_Jq_boundary=sqrt(.16)-abs(ref(:,2)-pred(:,2,1));
T.reference_rate_A_s=L.reference_ramp_rate_A_s(1:N);
T.phase=repmat("dynamic",N,1);T.phase(L.t_s(1:N)>=simulation.scenario.steady_window_start_s)="steady";
T.F_estimator_warmup=(1:N).'<=(project.assumptions.estimator_window_samples+1);
T.oracle_previous_valid=isfinite(Fprev0(:,1));T.P2c_noncausal=true(N,1);T.P3c_noncausal=true(N,1);
T.P0_recompute_gap_A=p0gap;T.P5_replay_gap_A=p5gap;T.F_previous_closure_A=prevClosure;
T.F_acausal_closure_A=curClosure;T.P2c_first_step_closure_A=p2cFirst;T.P4_identity_gap_A=p4Identity;
T.pending_u_d=uPending(:,1);T.pending_u_q=uPending(:,2);T.selected_u_d=uSelected(:,1);T.selected_u_q=uSelected(:,2);
T.applied_sequence_vector_ids=L.applied_sequence_vector_ids(1:N);T.applied_sequence_durations_s=L.applied_sequence_durations_s(1:N);
T.selected_sequence_vector_ids=L.selected_sequence_vector_ids(1:N);T.selected_sequence_durations_s=L.selected_sequence_durations_s(1:N);
T.original_sequence_vector_ids=L.original_sequence_vector_ids(1:N);T.original_sequence_durations_s=L.original_sequence_durations_s(1:N);

audit=struct('case_id',string(simulation.scenario.scenario_id),'sample_count',N, ...
    'P0_recompute_max_gap_A',max(p0gap),'P5_replay_max_gap_A',max(p5gap), ...
    'previous_F_closure_max_A',max(prevClosure,[],'omitnan'), ...
    'acausal_F_closure_max_A',max(curClosure),'P2c_first_step_max_gap_A',max(p2cFirst), ...
    'P4_identity_max_gap_A',max(p4Identity),'command_carry_pass',all(commandCarry));
end

function out=two_period(i,F,a,uP,uS,Ts)
out=i+Ts*(F+a.*uP)+Ts*(F+a.*uS);
end

function F=physical_F(i,omega,m)
F=[-m.Rs_Ohm/m.Ld_H*i(1)+omega*m.Lq_H/m.Ld_H*i(2); ...
   -m.Rs_Ohm/m.Lq_H*i(2)-omega*m.Ld_H/m.Lq_H*i(1)-omega*m.psi_f_Wb/m.Lq_H];
end

function command=parse_command(idsText,durText)
ids=parse_list(idsText);dur=parse_list(durText);
assert(numel(ids)==numel(dur),'ZhouModelError:CommandParse');
command=struct('sequence_vector_ids',ids(:).','sequence_durations_s',dur(:).');
end

function values=parse_list(text)
tokens=regexp(regexprep(char(string(text)),'[\[\]\(\)]',''),'[;,\s]+','split');tokens=tokens(~cellfun('isempty',tokens));values=str2double(tokens);
assert(~isempty(values)&&all(isfinite(values)),'ZhouModelError:NumericList');
end

function validate_command(c,Ts,tol)
assert(all(c.sequence_vector_ids>=0&c.sequence_vector_ids<=6&c.sequence_vector_ids==round(c.sequence_vector_ids)));
assert(all(c.sequence_durations_s>=-tol)&&abs(sum(c.sequence_durations_s)-Ts)<=max(tol,100*eps(Ts)),'ZhouModelError:Dwell');
end

function u=equivalent_voltage(c,vectors,theta,omega,delay,Ts)
u=zhou_ipmsm.controller.sequence_equivalent_dq_voltage(c,vectors,theta,omega,delay,Ts,"execution_segment_midpoint");
end

function yes=same_command(selected,idsText,durText,Ts)
other=parse_command(idsText,durText);yes=isequal(selected.sequence_vector_ids,other.sequence_vector_ids)&& ...
    max(abs(selected.sequence_durations_s-other.sequence_durations_s),[],'omitnan')<=max(1e-14,100*eps(Ts));
end

function out=physical_mode_column(ids,durs,Ts)
N=numel(ids);out=strings(N,1);
for k=1:N
    c=parse_command(ids(k),durs(k));keep=c.sequence_durations_s>max(100*eps(Ts),1e-15);
    count=numel(unique(c.sequence_vector_ids(keep),'stable'));
    if count==1,out(k)="one_vector";elseif count==2,out(k)="two_vector";elseif count==3,out(k)="three_vector";else,out(k)="multi_vector_"+count;end
end
end

function x=wrap_pi(x),x=mod(x+pi,2*pi)-pi;end
