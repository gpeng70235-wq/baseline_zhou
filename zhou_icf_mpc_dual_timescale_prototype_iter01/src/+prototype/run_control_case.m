function simulation = run_control_case(project,scenario,method,overrides)
%RUN_CONTROL_CASE Closed-loop B0/B1/B2/P/RLS comparison on a frozen case.
arguments
    project struct
    scenario struct
    method (1,1) string {mustBeMember(method,["B0","B1","B2","P","RLS"])}
    overrides struct = struct()
end
p=project.paper;a=project.assumptions;ep=project.parameters;
ep=apply_overrides(ep,overrides);
assert(p.Ts_s==ep.Ts_s&&scenario.Jd_limit_A2==.16&&scenario.Jq_limit_A2==.16, ...
    'Prototype:FrozenConfigurationDrift');
dc_bus=field_or(scenario,'dc_bus_V',a.dc_bus_V);
scale=field_or(scenario,'voltage_vector_scale',a.voltage_vector_scale);
vectors=zhou_ipmsm.inverter.voltage_vectors(dc_bus,scale);
controller_paper=p;plant_paper=p;
if string(field_or(scenario,'motor_model',"P1"))=="P0"
    plant_paper.Ld_H=p.Ls_H;plant_paper.Lq_H=p.Ls_H;
else
    plant_paper.Ld_H=p.Ld_H*field_or(scenario,'plant_Ld_scale',1);
    plant_paper.Lq_H=p.Lq_H*field_or(scenario,'plant_Lq_scale',1);
end
plant_paper.Rs_Ohm=p.Rs_Ohm*field_or(scenario,'plant_Rs_scale',1);
plant_paper.psi_f_Wb=p.psi_f_Wb*field_or(scenario,'plant_psi_f_scale',1);
if string(field_or(scenario,'alpha_mode',"axis_specific"))=="axis_specific"
    if string(field_or(scenario,'motor_model',"P1"))=="P0"
        controller_paper.alpha_d=1/p.Ls_H;controller_paper.alpha_q=1/p.Ls_H;
    else
        controller_paper.alpha_d=1/p.Ld_H;controller_paper.alpha_q=1/p.Lq_H;
    end
else
    controller_paper.alpha_d=1/p.Ls_H;controller_paper.alpha_q=1/p.Ls_H;
end
cfg=struct('paper',controller_paper,'assumptions',a,'vectors',vectors, ...
    'Jd_limit',scenario.Jd_limit_A2,'Jq_limit',scenario.Jq_limit_A2);
Ts=p.Ts_s;steps=round(scenario.simulation_time_s/Ts);
omega_e=p.pole_pairs*scenario.speed_rpm*2*pi/60;
rng(field_or(scenario,'random_seed',project.base.random_seed),'twister');
noise_std=field_or(scenario,'measurement_noise_std_A',0);
angle_error=deg2rad(field_or(scenario,'angle_error_deg',0));
dead_time_s=field_or(scenario,'dead_time_s',0);voltage_drop=field_or(scenario,'voltage_drop_V',0);
steady_init=logical(field_or(scenario,'diagnostic_steady_initialization',false));
if steady_init,state=[scenario.id_ref_A;scenario.iq_ref_A;scenario.theta0_rad];
else,state=[scenario.id0_A;scenario.iq0_A;scenario.theta0_rad];end
measured=state(1:2)+noise_std*randn(2,1);previous=measured;
[equilibrium_dq,plant_F]=equilibrium_and_F(state(1:2),omega_e,plant_paper);
controller_alpha=[controller_paper.alpha_d;controller_paper.alpha_q];
initial_F=plant_F+([1/plant_paper.Ld_H;1/plant_paper.Lq_H]-controller_alpha).*equilibrium_dq;
cfg.assumptions.estimator_initial_F_dq=initial_F.';
equilibrium_ab=zhou_ipmsm.math.inv_park(equilibrium_dq,state(3)).';
if norm(equilibrium_ab)<=a.voltage_tolerance_V
    pending=zhou_ipmsm.modulation.case1_command(Ts,vectors);
else
    pending=zhou_ipmsm.modulation.case3_command(equilibrium_ab,Ts,vectors, ...
        a.sector_angle_tolerance_rad,a.duty_tolerance);
end
pending.case_id=0;pending.selected_vector=NaN;pending.reference_dq_at_selection=equilibrium_dq;
pending.theta_at_selection=state(3);last_u_app=equilibrium_dq;
history_N=a.estimator_window_samples;
current_history=repmat(measured,1,history_N+1);applied_history=repmat(last_u_app,1,history_N);
est=prototype.estimator_initialize(ep);completed_log=[];pending_pre_u=equilibrium_dq;

numeric_names=["sample_index","time_s","id","iq","id_ref","iq_ref","torque", ...
    "torque_ref","speed_rpm","theta","Vdc","alpha_d","alpha_q","F_d","F_q", ...
    "F_pred_d","F_pred_q","u_target_d","u_target_q","u_app_prev_d","u_app_prev_q", ...
    "u_pending_d","u_pending_q","u_selected_final_d","u_selected_final_q", ...
    "i_pred_k1_d","i_pred_k1_q","i_pred_k2_d","i_pred_k2_q", ...
    "Jd_pred","Jq_pred","Jd_actual","Jq_actual","false_safe","false_alarm", ...
    "mode","selected_core","selected_final","S2_triggered","voltage_utilization", ...
    "gate_exc_d","gate_exc_q","gate_s2","gate_decision","alpha_update_d", ...
    "alpha_update_q","reset_event","execution_time_us","timing_assertion_pass", ...
    "projection_hit_d","projection_hit_q","u_hp_d","u_hp_q","y_hp_d","y_hp_q", ...
    "window_energy_d","window_energy_q","regressor_rcond_d","regressor_rcond_q", ...
    "reconstruction_residual_V","alpha_step_scale","native_margin_A2", ...
    "native_mode_gap_A2","actual_d_violation","actual_q_violation", ...
    "illegal_duration","switching_actions"];
D=struct();for name=numeric_names,D.(name)=NaN(steps,1);end
string_names=["case_id","method","range_class","category","pending_command_id", ...
    "selected_core_id","selected_final_id","freeze_reason_d","freeze_reason_q", ...
    "estimator_state_d","estimator_state_q"];
S=struct();for name=string_names,S.(name)=strings(steps,1);end
completed=false;executed=0;illegal=false;previous_reference=[0;0];
for k=1:steps
    t=(k-1)*Ts;theta_start=state(3);
    reference=reference_at_time(scenario,t,steady_init);
    current=state(1:2);controller_theta=state(3)+angle_error;
    input=struct('current_dq',measured,'previous_current_dq',previous, ...
        'last_applied_voltage_dq',last_u_app,'pending_voltage_dq',pending.reference_dq_at_selection, ...
        'pending_command',pending,'omega_e',omega_e,'pending_vector_id',0, ...
        'estimator_history_valid',k>1,'reference_dq',reference,'theta_e',controller_theta, ...
        'current_history_dq',current_history,'applied_history_dq',applied_history);
    controller_timer=tic;
    if method=="B0"
        ed=empty_estimator_diag();quality=empty_quality();
        core=zhou_ipmsm.controller.icf_mpc_step(input,cfg);
        [control,layer]=zhou_feasibility.apply_feasibility_layer(core,input,cfg,"proposed_feasibility_aware");
        alpha_used=controller_alpha;F_used=control.Fhat_dq;Fpred_used=F_used;
        decision_next=false;native_margin=min(cfg.Jd_limit-core.Jd,cfg.Jq_limit-core.Jq);
        native_gap=abs(core.Jd-core.Jq);
    else
        quality=prototype.s2_input_quality_gate(completed_log,ep);
        original_F=zhou_ipmsm.controller.estimate_F_algebraic(current_history, ...
            applied_history,controller_alpha,Ts);
        estimator_u=last_u_app;
        if ep.use_pre_s2_voltage&&~isempty(completed_log),estimator_u=completed_log.u_pre;end
        [est,ed]=prototype.estimator_step(est,method,measured,previous,estimator_u,quality,original_F,ep);
        provider=struct('alpha',est.alpha,'F',est.F,'F_pred',est.F_pred);
        core=prototype.icf_mpc_step(input,cfg,provider);
        [control,layer]=zhou_feasibility.apply_feasibility_layer(core,input,cfg,"proposed_feasibility_aware");
        control=prototype.finalize_after_s2(control,input,cfg,provider);
        alpha_used=est.alpha;F_used=est.F;Fpred_used=est.F_pred;
        native_gap=core.native_mode_gap_A2;
        [decision_next,native_margin]=prototype.decision_margin_gate(core.Jd,core.Jq, ...
            cfg.Jd_limit,cfg.Jq_limit,native_gap,true,ep);
    end
    controller_elapsed_us=toc(controller_timer)*1e6;
    selected=control.command;next_pre_u=core.selected_voltage_dq_used;
    selected_feas=zhou_feasibility.voltage_feasibility(selected.reference_ab_V,vectors,selected,a.duty_tolerance);
    u_target=core.selected_voltage_dq_used;u_selected=control.selected_voltage_dq_used;
    torque=zhou_ipmsm.model.electromagnetic_torque(current,plant_paper);
    torque_ref=zhou_ipmsm.model.electromagnetic_torque(reference,plant_paper);
    executed=k;
    D.sample_index(k)=k;D.time_s(k)=t;D.id(k)=current(1);D.iq(k)=current(2);
    D.id_ref(k)=reference(1);D.iq_ref(k)=reference(2);D.torque(k)=torque;D.torque_ref(k)=torque_ref;
    D.speed_rpm(k)=scenario.speed_rpm;D.theta(k)=state(3);D.Vdc(k)=dc_bus;
    D.alpha_d(k)=alpha_used(1);D.alpha_q(k)=alpha_used(2);D.F_d(k)=F_used(1);D.F_q(k)=F_used(2);
    D.F_pred_d(k)=Fpred_used(1);D.F_pred_q(k)=Fpred_used(2);
    D.u_target_d(k)=u_target(1);D.u_target_q(k)=u_target(2);
    D.u_app_prev_d(k)=last_u_app(1);D.u_app_prev_q(k)=last_u_app(2);
    D.u_pending_d(k)=control.pending_voltage_dq_used(1);D.u_pending_q(k)=control.pending_voltage_dq_used(2);
    D.u_selected_final_d(k)=u_selected(1);D.u_selected_final_q(k)=u_selected(2);
    D.i_pred_k1_d(k)=control.predicted_k1_dq(1);D.i_pred_k1_q(k)=control.predicted_k1_dq(2);
    D.i_pred_k2_d(k)=control.predicted_k2_dq(1);D.i_pred_k2_q(k)=control.predicted_k2_dq(2);
    D.Jd_pred(k)=control.Jd;D.Jq_pred(k)=control.Jq;D.mode(k)=selected.case_id;
    D.selected_core(k)=core.command.case_id;D.selected_final(k)=selected.case_id;
    D.S2_triggered(k)=layer.modified&&~layer.fallback_used;D.voltage_utilization(k)=selected_feas.utilization_ratio;
    D.gate_exc_d(k)=ed.gate_exc(1);D.gate_exc_q(k)=ed.gate_exc(2);D.gate_s2(k)=quality.pass;
    if method=="B0",D.gate_decision(k)=0;else,D.gate_decision(k)=est.decision_gate_latched;end
    D.alpha_update_d(k)=ed.alpha_update(1);D.alpha_update_q(k)=ed.alpha_update(2);
    D.reset_event(k)=0;D.execution_time_us(k)=controller_elapsed_us;
    D.projection_hit_d(k)=ed.projection_hit(1);D.projection_hit_q(k)=ed.projection_hit(2);
    D.u_hp_d(k)=ed.u_hp(1);D.u_hp_q(k)=ed.u_hp(2);D.y_hp_d(k)=ed.y_hp(1);D.y_hp_q(k)=ed.y_hp(2);
    D.window_energy_d(k)=ed.energy(1);D.window_energy_q(k)=ed.energy(2);
    D.regressor_rcond_d(k)=ed.rcond(1);D.regressor_rcond_q(k)=ed.rcond(2);
    D.reconstruction_residual_V(k)=quality.reconstruction_residual_V;D.alpha_step_scale(k)=quality.step_scale;
    D.native_margin_A2(k)=native_margin;D.native_mode_gap_A2(k)=native_gap;
    D.illegal_duration(k)=any(selected.sequence_durations_s<-a.time_tolerance_s);
    D.switching_actions(k)=pending.switching_actions;
    D.timing_assertion_pass(k)=double(k==1||S.selected_final_id(k-1)==command_signature(pending));
    S.case_id(k)=string(scenario.scenario_id);S.method(k)=method;
    S.range_class(k)=string(scenario.range_class);S.category(k)=string(scenario.case_category);
    S.pending_command_id(k)=command_signature(pending);S.selected_core_id(k)=command_signature(core.command);
    S.selected_final_id(k)=command_signature(selected);S.freeze_reason_d(k)=ed.freeze_reason(1);
    S.freeze_reason_q(k)=ed.freeze_reason(2);S.estimator_state_d(k)=ed.state(1);S.estimator_state_q(k)=ed.state(2);
    if method~="B0",est.decision_gate_latched=decision_next;end
    pending_illegal=~pending.legal||any(pending.sequence_durations_s<-a.time_tolerance_s);
    if pending_illegal,illegal=true;break;end
    delta_ab=[0,0];
    if dead_time_s>0
        [dd,~]=zhou_ipmsm.inverter.deadtime_voltage_error(pending,current,state(3),dc_bus, ...
            dead_time_s,Ts,a.deadtime_current_zero_tolerance_A);delta_ab=delta_ab+dd;
    end
    if voltage_drop>0&&norm(pending.equivalent_ab_V)>a.voltage_tolerance_V
        delta_ab=delta_ab-voltage_drop*pending.equivalent_ab_V/norm(pending.equivalent_ab_V);
    end
    [next,u_executed,~]=prototype.plant_update(state,pending,vectors,omega_e,plant_paper,Ts, ...
        a.time_tolerance_s,delta_ab,scenario.integration_step_s);
    completed_log=struct('command',pending,'u_app',u_executed,'u_pre',pending_pre_u, ...
        'vectors',vectors,'theta_start',theta_start,'omega_e',omega_e,'Vdc',dc_bus);
    previous=measured;state=next;measured=state(1:2)+noise_std*randn(2,1);
    last_u_app=u_executed;current_history=[current_history(:,2:end),measured];
    applied_history=[applied_history(:,2:end),u_executed];pending=selected;pending_pre_u=next_pre_u;
    previous_reference=reference; %#ok<NASGU>
    if k==steps,completed=true;end
end
for j=1:max(0,executed-2)
    D.Jd_actual(j)=(D.id_ref(j)-D.id(j+2))^2;D.Jq_actual(j)=(D.iq_ref(j)-D.iq(j+2))^2;
    predicted_safe=D.Jd_pred(j)<=.16+1e-12&&D.Jq_pred(j)<=.16+1e-12;
    actual_safe=D.Jd_actual(j)<=.16+1e-12&&D.Jq_actual(j)<=.16+1e-12;
    D.actual_d_violation(j)=D.Jd_actual(j)>.16+1e-12;D.actual_q_violation(j)=D.Jq_actual(j)>.16+1e-12;
    D.false_safe(j)=predicted_safe&&~actual_safe;D.false_alarm(j)=~predicted_safe&&actual_safe;
end
for name=numeric_names,D.(name)=D.(name)(1:executed);end
for name=string_names,S.(name)=S.(name)(1:executed);end
trace=[struct2table(S),struct2table(D)];
summary=prototype.case_metrics(trace,scenario,completed,illegal);
simulation=struct('scenario',scenario,'method',method,'trace',trace,'summary',summary, ...
    'completed',completed,'illegal_event',illegal,'plant_motor',plant_paper, ...
    'controller_motor',controller_paper,'parameters',ep);
end

function r=reference_at_time(s,t,steady)
profile=string(field_or(s,'profile_type',field_or(s,'reference_profile',"ramp")));
if steady||profile=="constant",r=[s.id_ref_A;s.iq_ref_A];
elseif profile=="two_step"
    if t<field_or(s,'current_step_time_s',.05)
        ramp=min(1,t/max(s.reference_ramp_s,eps));r=.5*[s.id_ref_A;s.iq_ref_A]*ramp;
    else,r=[s.id_ref_A;s.iq_ref_A];end
else,r=[s.id_ref_A;s.iq_ref_A]*min(1,t/max(s.reference_ramp_s,eps));end
end
function s=command_signature(c)
s=join(string(c.sequence_vector_ids),';')+"|"+join(compose('%.17g',c.sequence_durations_s),';');
end
function d=empty_estimator_diag()
d=struct('y',[NaN;NaN],'u_hp',[NaN;NaN],'y_hp',[NaN;NaN], ...
    'gate_exc',false(2,1),'gate_s2',false,'alpha_update',false(2,1), ...
    'freeze_reason',["baseline";"baseline"],'projection_hit',false(2,1), ...
    'energy',[NaN;NaN],'rcond',[NaN;NaN],'residual_jump',[NaN;NaN], ...
    'state',["baseline";"baseline"]);
end
function q=empty_quality()
q=struct('pass',false,'reason',"baseline",'step_scale',0, ...
    'reconstruction_residual_V',NaN,'utilization',NaN,'zero_command',false, ...
    'u_reconstructed',[NaN;NaN]);
end
function p=apply_overrides(p,o)
names=fieldnames(o);for k=1:numel(names),p.(names{k})=o.(names{k});end
end
function value=field_or(s,name,default_value)
if isfield(s,name),value=s.(name);else,value=default_value;end
end
function [u,F]=equilibrium_and_F(i,omega,m)
u=[m.Rs_Ohm*i(1)-omega*m.Lq_H*i(2);m.Rs_Ohm*i(2)+omega*(m.Ld_H*i(1)+m.psi_f_Wb)];
F=[-m.Rs_Ohm/m.Ld_H*i(1)+omega*m.Lq_H/m.Ld_H*i(2); ...
    -m.Rs_Ohm/m.Lq_H*i(2)-omega*m.Ld_H/m.Lq_H*i(1)-omega*m.psi_f_Wb/m.Lq_H];
end
