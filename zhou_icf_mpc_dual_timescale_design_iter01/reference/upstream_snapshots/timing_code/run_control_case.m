function simulation = run_control_case(project,scenario,strategy)
%RUN_CONTROL_CASE Instrumented closed loop with an explicit feasibility layer.
% The copied controller and modulation functions are called without changes.
% An illegal applied command terminates integration only after its complete
% diagnostic row has been retained.

arguments
    project struct
    scenario struct
    strategy (1,1) string {mustBeMember(strategy,["original_zhou", ...
        "radial_hex_projection","proposed_feasibility_aware"])} = "original_zhou"
end

p=project.paper;
a=project.assumptions;
dc_bus=field_or(scenario,'dc_bus_V',a.dc_bus_V);
scale=field_or(scenario,'voltage_vector_scale',a.voltage_vector_scale);
vectors=zhou_ipmsm.inverter.voltage_vectors(dc_bus,scale);
controller_paper=p;
plant_paper=p;
if string(field_or(scenario,'motor_model',"P1"))=="P0"
    plant_paper.Ld_H=plant_paper.Ls_H;
    plant_paper.Lq_H=plant_paper.Ls_H;
else
    plant_paper.Ld_H=plant_paper.Ld_H*field_or(scenario,'plant_Ld_scale',1);
    plant_paper.Lq_H=plant_paper.Lq_H*field_or(scenario,'plant_Lq_scale',1);
end
plant_paper.Rs_Ohm=plant_paper.Rs_Ohm*field_or(scenario,'plant_Rs_scale',1);
plant_paper.psi_f_Wb=plant_paper.psi_f_Wb*field_or(scenario,'plant_psi_f_scale',1);
if string(field_or(scenario,'alpha_mode',"axis_specific"))=="axis_specific"
    if string(field_or(scenario,'motor_model',"P1"))=="P0"
        controller_paper.alpha_d=1/p.Ls_H;
        controller_paper.alpha_q=1/p.Ls_H;
    else
        controller_paper.alpha_d=1/p.Ld_H;
        controller_paper.alpha_q=1/p.Lq_H;
    end
else
    controller_paper.alpha_d=1/p.Ls_H;
    controller_paper.alpha_q=1/p.Ls_H;
end
cfg=struct('paper',controller_paper,'assumptions',a,'vectors',vectors, ...
    'Jd_limit',scenario.Jd_limit_A2,'Jq_limit',scenario.Jq_limit_A2);

Ts=p.Ts_s;
steps=round(scenario.simulation_time_s/Ts);
omega_m=scenario.speed_rpm*2*pi/60;
omega_e=p.pole_pairs*omega_m;
steady_init=logical(field_or(scenario,'diagnostic_steady_initialization',false));
if steady_init
    state=[scenario.id_ref_A;scenario.iq_ref_A;scenario.theta0_rad];
else
    state=[scenario.id0_A;scenario.iq0_A;scenario.theta0_rad];
end
previous_current=state(1:2);

% Causal initialization: equilibrium is computed only from configured
% parameters and the present initial state. No future samples are used.
[equilibrium_dq,plant_F]=equilibrium_and_F(state(1:2),omega_e,plant_paper);
controller_alpha=[controller_paper.alpha_d;controller_paper.alpha_q];
initial_F=plant_F+([1/plant_paper.Ld_H;1/plant_paper.Lq_H]-controller_alpha).*equilibrium_dq;
cfg.assumptions.estimator_initial_F_dq=initial_F.';
equilibrium_ab=zhou_ipmsm.math.inv_park(equilibrium_dq,state(3)).';
if norm(equilibrium_ab)<=a.voltage_tolerance_V
    applied_command=zhou_ipmsm.modulation.case1_command(Ts,vectors);
else
    applied_command=zhou_ipmsm.modulation.case3_command(equilibrium_ab,Ts,vectors, ...
        a.sector_angle_tolerance_rad,a.duty_tolerance);
end
applied_command.case_id=0;
applied_command.selected_vector=NaN;
applied_command.reference_dq_at_selection=equilibrium_dq;
applied_command.theta_at_selection=state(3);
last_applied_voltage_dq=equilibrium_dq;
history_N=a.estimator_window_samples;
current_history=repmat(state(1:2),1,history_N+1);
applied_history=repmat(last_applied_voltage_dq,1,history_N);

names=["t_s","id_ref_A","iq_ref_A","id_A","iq_A","id_error_A","iq_error_A", ...
    "Vd","Vq","rectangle_center_d_V","rectangle_center_q_V", ...
    "rectangle_center_alpha_V","rectangle_center_beta_V","rectangle_half_d_V", ...
    "rectangle_half_q_V","theta_e_rad","sector","case_id","d0","d1","d2", ...
    "duty_sum","minimum_duty","active_vector_1","active_vector_2", ...
    "V1_alpha_V","V1_beta_V","V2_alpha_V","V2_beta_V", ...
    "reference_alpha_V","reference_beta_V","reference_voltage_magnitude_V", ...
    "hex_radial_limit_V","voltage_utilization_ratio","inside_hexagon", ...
    "inside_halfspace","inside_barycentric","hex_margin_V","barycentric_rho", ...
    "barycentric_identity_residual","geometry_false_positive","geometry_false_negative", ...
    "selected_case","pending_case","applied_case","selected_legal","pending_legal", ...
    "applied_legal","applied_d0","applied_d1","applied_d2", ...
    "applied_reference_alpha_V","applied_reference_beta_V", ...
    "applied_voltage_utilization_ratio","applied_hex_margin_V", ...
    "Fd_hat","Fq_hat","Fd_true","Fq_true","Fd_residual","Fq_residual", ...
    "alpha_d","alpha_q","U3d","U3q","torque_Nm","switching_actions_applied", ...
    "integration_time_residual_s","geometry_theta_rad","original_case","original_legal", ...
    "original_d0","original_d1","original_d2","original_reference_alpha_V", ...
    "original_reference_beta_V","layer_modified","degenerated_to_original", ...
    "intersection_nonempty","intersection_area_V2","radial_point_inside_rectangle", ...
    "fallback_used","fallback_consecutive_cycles","fallback_Jd_ratio", ...
    "fallback_Jq_ratio","fallback_d_violation","fallback_q_violation", ...
    "target_offset_ab_V","target_offset_normalized","predicted_d_satisfied", ...
    "predicted_q_satisfied","actual_d_constraint_violated", ...
    "actual_q_constraint_violated","controller_execution_time_s", ...
    "feasibility_layer_time_s","negative_duration_selected", ...
    "switching_actions_selected","original_switching_actions_selected"];
D=struct();
for name=names, D.(name)=NaN(steps,1); end
selected_sequence_ids=strings(steps,1);selected_sequence_durations=strings(steps,1);
original_sequence_ids=strings(steps,1);original_sequence_durations=strings(steps,1);

illegal_event=struct('occurred',false,'selected_time_s',NaN,'applied_time_s',NaN, ...
    'duties',[NaN NaN NaN],'reference_ab_V',[NaN NaN],'case_id',NaN);
selected_illegal_time=NaN;
completed=false;
executed=0;
fallback_streak=0;
for k=1:steps
    t=(k-1)*Ts;
    if steady_init || string(field_or(scenario,'reference_profile',"ramp"))=="constant"
        ramp=1;
    else
        ramp=min(1,t/max(scenario.reference_ramp_s,eps));
    end
    reference_dq=[scenario.id_ref_A;scenario.iq_ref_A]*ramp;
    current_dq=state(1:2);
    input=struct('current_dq',current_dq,'previous_current_dq',previous_current, ...
        'last_applied_voltage_dq',last_applied_voltage_dq, ...
        'pending_voltage_dq',applied_command.reference_dq_at_selection, ...
        'pending_command',applied_command,'omega_e',omega_e,'pending_vector_id',0, ...
        'estimator_history_valid',k>1,'reference_dq',reference_dq, ...
        'theta_e',state(3),'current_history_dq',current_history, ...
        'applied_history_dq',applied_history);
    total_timer=tic;
    core_control=zhou_ipmsm.controller.icf_mpc_step(input,cfg);
    [control,layer]=zhou_feasibility.apply_feasibility_layer( ...
        core_control,input,cfg,strategy);
    controller_elapsed=toc(total_timer);
    selected=control.command;
    selected_feas=zhou_feasibility.voltage_feasibility( ...
        selected.reference_ab_V,vectors,selected,a.duty_tolerance);
    applied_feas=zhou_feasibility.voltage_feasibility( ...
        applied_command.reference_ab_V,vectors,applied_command,a.duty_tolerance);
    [~,Ftrue]=equilibrium_and_F(current_dq,omega_e,plant_paper);
    torque=zhou_ipmsm.model.electromagnetic_torque(current_dq,plant_paper);
    rect=control.geometry.rect;

    executed=k;
    D.t_s(k)=t; D.id_ref_A(k)=reference_dq(1); D.iq_ref_A(k)=reference_dq(2);
    D.id_A(k)=current_dq(1); D.iq_A(k)=current_dq(2);
    D.id_error_A(k)=reference_dq(1)-current_dq(1);
    D.iq_error_A(k)=reference_dq(2)-current_dq(2);
    D.Vd(k)=control.V_dq(1); D.Vq(k)=control.V_dq(2);
    D.rectangle_center_d_V(k)=rect.center_dq(1); D.rectangle_center_q_V(k)=rect.center_dq(2);
    D.rectangle_center_alpha_V(k)=rect.center_ab(1); D.rectangle_center_beta_V(k)=rect.center_ab(2);
    D.rectangle_half_d_V(k)=rect.half_dq(1); D.rectangle_half_q_V(k)=rect.half_dq(2);
    D.theta_e_rad(k)=state(3); D.sector(k)=field_or(selected,'sector',selected_feas.sector);
    D.case_id(k)=selected.case_id;
    duties=three_duties(selected); D.d0(k)=duties(1); D.d1(k)=duties(2); D.d2(k)=duties(3);
    D.duty_sum(k)=sum(duties); D.minimum_duty(k)=min(duties);
    D.active_vector_1(k)=selected_feas.active_vector_ids(1);
    D.active_vector_2(k)=selected_feas.active_vector_ids(2);
    D.V1_alpha_V(k)=selected_feas.V1_ab(1); D.V1_beta_V(k)=selected_feas.V1_ab(2);
    D.V2_alpha_V(k)=selected_feas.V2_ab(1); D.V2_beta_V(k)=selected_feas.V2_ab(2);
    D.reference_alpha_V(k)=selected.reference_ab_V(1); D.reference_beta_V(k)=selected.reference_ab_V(2);
    D.reference_voltage_magnitude_V(k)=selected_feas.magnitude_V;
    D.hex_radial_limit_V(k)=selected_feas.hex_radial_limit_V;
    D.voltage_utilization_ratio(k)=selected_feas.utilization_ratio;
    D.inside_hexagon(k)=selected_feas.inside_hexagon;
    D.inside_halfspace(k)=selected_feas.inside_halfspace;
    D.inside_barycentric(k)=selected_feas.inside_barycentric;
    D.hex_margin_V(k)=selected_feas.hex_margin_V;
    D.barycentric_rho(k)=selected_feas.rho;
    D.barycentric_identity_residual(k)=selected_feas.identity_residual;
    D.geometry_false_positive(k)=selected_feas.false_positive;
    D.geometry_false_negative(k)=selected_feas.false_negative;
    D.selected_case(k)=selected.case_id; D.pending_case(k)=selected.case_id;
    D.applied_case(k)=applied_command.case_id;
    D.selected_legal(k)=selected.legal; D.pending_legal(k)=selected.legal;
    D.applied_legal(k)=applied_command.legal;
    ad=three_duties(applied_command); D.applied_d0(k)=ad(1); D.applied_d1(k)=ad(2); D.applied_d2(k)=ad(3);
    D.applied_reference_alpha_V(k)=applied_command.reference_ab_V(1);
    D.applied_reference_beta_V(k)=applied_command.reference_ab_V(2);
    D.applied_voltage_utilization_ratio(k)=applied_feas.utilization_ratio;
    D.applied_hex_margin_V(k)=applied_feas.hex_margin_V;
    D.Fd_hat(k)=control.Fhat_dq(1); D.Fq_hat(k)=control.Fhat_dq(2);
    D.Fd_true(k)=Ftrue(1); D.Fq_true(k)=Ftrue(2);
    D.Fd_residual(k)=control.Fhat_dq(1)-Ftrue(1); D.Fq_residual(k)=control.Fhat_dq(2)-Ftrue(2);
    D.alpha_d(k)=controller_paper.alpha_d; D.alpha_q(k)=controller_paper.alpha_q;
    D.U3d(k)=control.pending_voltage_dq_used(1); D.U3q(k)=control.pending_voltage_dq_used(2);
    D.torque_Nm(k)=torque; D.switching_actions_applied(k)=applied_command.switching_actions;
    D.geometry_theta_rad(k)=control.geometry_theta;

    od=three_duties(core_control.command);
    D.original_case(k)=core_control.command.case_id;D.original_legal(k)=core_control.command.legal;
    D.original_d0(k)=od(1);D.original_d1(k)=od(2);D.original_d2(k)=od(3);
    D.original_reference_alpha_V(k)=core_control.command.reference_ab_V(1);
    D.original_reference_beta_V(k)=core_control.command.reference_ab_V(2);
    D.layer_modified(k)=layer.modified;D.degenerated_to_original(k)=layer.degenerated_to_original;
    D.intersection_nonempty(k)=field_or(layer.intersection,'nonempty',NaN);
    D.intersection_area_V2(k)=field_or(layer.intersection,'area_V2',NaN);
    D.radial_point_inside_rectangle(k)=layer.radial_point_inside_rectangle;
    D.fallback_used(k)=layer.fallback_used;
    if layer.fallback_used,fallback_streak=fallback_streak+1;else,fallback_streak=0;end
    D.fallback_consecutive_cycles(k)=fallback_streak;
    D.fallback_Jd_ratio(k)=layer.fallback_Jd_ratio;D.fallback_Jq_ratio(k)=layer.fallback_Jq_ratio;
    D.fallback_d_violation(k)=layer.fallback_d_violation;D.fallback_q_violation(k)=layer.fallback_q_violation;
    D.target_offset_ab_V(k)=layer.offset_ab_V;D.target_offset_normalized(k)=layer.offset_normalized;
    D.predicted_d_satisfied(k)=control.constraint_satisfied_d;
    D.predicted_q_satisfied(k)=control.constraint_satisfied_q;
    D.actual_d_constraint_violated(k)=D.id_error_A(k)^2>scenario.Jd_limit_A2+a.constraint_tolerance;
    D.actual_q_constraint_violated(k)=D.iq_error_A(k)^2>scenario.Jq_limit_A2+a.constraint_tolerance;
    D.controller_execution_time_s(k)=controller_elapsed;
    D.feasibility_layer_time_s(k)=layer.layer_execution_time_s;
    D.negative_duration_selected(k)=any(selected.sequence_durations_s<-a.time_tolerance_s);
    D.switching_actions_selected(k)=selected.switching_actions;
    D.original_switching_actions_selected(k)=core_control.command.switching_actions;
    selected_sequence_ids(k)=join(string(selected.sequence_vector_ids),';');
    selected_sequence_durations(k)=join(compose('%.17g',selected.sequence_durations_s),';');
    original_sequence_ids(k)=join(string(core_control.command.sequence_vector_ids),';');
    original_sequence_durations(k)=join(compose('%.17g',core_control.command.sequence_durations_s),';');

    if ~selected.legal && isnan(selected_illegal_time), selected_illegal_time=t; end
    if ~applied_command.legal
        illegal_event.occurred=true;
        illegal_event.selected_time_s=selected_illegal_time;
        illegal_event.applied_time_s=t;
        illegal_event.duties=ad;
        illegal_event.reference_ab_V=applied_command.reference_ab_V;
        illegal_event.case_id=applied_command.case_id;
        break
    end

    [next_state,applied_average_dq,audit]=zhou_ipmsm.model.integrate_command( ...
        state,applied_command,vectors,omega_e,plant_paper,Ts,a.time_tolerance_s, ...
        [0,0],scenario.integration_step_s);
    D.integration_time_residual_s(k)=audit.time_residual_s;
    previous_current=current_dq;
    state=next_state;
    last_applied_voltage_dq=applied_average_dq;
    current_history=[current_history(:,2:end),state(1:2)];
    applied_history=[applied_history(:,2:end),applied_average_dq];
    applied_command=selected;
    if k==steps, completed=true; end
end

for name=names, D.(name)=D.(name)(1:executed); end
trace=struct2table(D);
trace=addvars(trace,selected_sequence_ids(1:executed),selected_sequence_durations(1:executed), ...
    original_sequence_ids(1:executed),original_sequence_durations(1:executed), ...
    'NewVariableNames',{'selected_sequence_vector_ids','selected_sequence_durations_s', ...
    'original_sequence_vector_ids','original_sequence_durations_s'});
trace=addvars(trace,repmat(dc_bus,executed,1),repmat(scale,executed,1), ...
    repmat(dc_bus*scale,executed,1),repmat(scenario.reference_ramp_s,executed,1), ...
    repmat(Ts,executed,1),repmat(string(scenario.motor_model),executed,1), ...
    repmat(plant_paper.Ld_H,executed,1),repmat(plant_paper.Lq_H,executed,1), ...
    repmat(string(scenario.alpha_mode),executed,1), ...
    repmat(string(scenario.F_estimator),executed,1),repmat(strategy,executed,1), ...
    'NewVariableNames',{'dc_bus_V','voltage_vector_scale', ...
    'active_vector_magnitude_V','reference_ramp_s','sampling_period_s', ...
    'motor_model','Ld_H','Lq_H','alpha_mode','F_estimator','strategy'});
summary=summarize_trace(trace,scenario,project,dc_bus,scale,vectors,completed,illegal_event,plant_paper,strategy);
simulation=struct('scenario',scenario,'trace',trace,'summary',summary, ...
    'completed',completed,'illegal_event',illegal_event,'vectors',vectors, ...
    'plant_motor',plant_paper,'controller_motor',controller_paper, ...
    'runtime_assumptions',struct('dc_bus_V',dc_bus,'voltage_vector_scale',scale, ...
    'active_vector_magnitude_V',dc_bus*scale,'reference_ramp_s',scenario.reference_ramp_s, ...
    'sampling_period_s',Ts,'integration_step_s',scenario.integration_step_s));
end

function summary=summarize_trace(T,s,project,vdc,scale,vectors,completed,event,motor,strategy)
steady=T.t_s>=s.steady_window_start_s;
id_rmse=sqrt(mean(T.id_error_A.^2)); iq_rmse=sqrt(mean(T.iq_error_A.^2));
thd=NaN; torque_mean=NaN; torque_ripple=NaN; steady_max_util=NaN; steady_neg=false;
steady_id_rmse=NaN;steady_iq_rmse=NaN;
if completed && nnz(steady)>10
    theta=T.theta_e_rad(steady); id=T.id_A(steady); iq=T.iq_A(steady);
    ia=cos(theta).*id-sin(theta).*iq;
    [thd,~,~]=zhou_ipmsm.metrics.phase_thd_total_rms(ia,T.t_s(steady), ...
        s.speed_rpm/60*motor.pole_pairs);
    torque_mean=mean(T.torque_Nm(steady)); torque_ripple=std(T.torque_Nm(steady));
    steady_max_util=max(T.voltage_utilization_ratio(steady));
    steady_neg=any(T.d0(steady)<-project.assumptions.duty_tolerance);
    steady_id_rmse=sqrt(mean(T.id_error_A(steady).^2));
    steady_iq_rmse=sqrt(mean(T.iq_error_A(steady).^2));
end
first_timed=min(height(T),floor(project.assumptions.exec_time_exclude_fraction*height(T))+1);
exec=T.controller_execution_time_s(first_timed:end);
fallback_cycles=nnz(T.fallback_used);max_fallback=max(T.fallback_consecutive_cycles);
pred_d_rate=mean(T.predicted_d_satisfied);pred_q_rate=mean(T.predicted_q_satisfied);
actual_d_rate=mean(T.actual_d_constraint_violated);actual_q_rate=mean(T.actual_q_constraint_violated);
summary=table(string(project.run_id),string(s.name),s.speed_rpm,s.id_ref_A,s.iq_ref_A, ...
    string(s.motor_model),vdc,scale, ...
    vdc*scale,s.reference_ramp_s,project.base.Ts_s,motor.Ld_H,motor.Lq_H, ...
    string(s.alpha_mode),string(s.F_estimator),completed,event.occurred, ...
    event.applied_time_s,event.selected_time_s,min(T.d0),max(T.voltage_utilization_ratio), ...
    max(T.reference_voltage_magnitude_V),max(max(-T.hex_margin_V,0)), ...
    id_rmse,iq_rmse,thd,torque_mean,torque_ripple,sum(T.switching_actions_applied), ...
    height(T),steady_max_util,steady_neg,steady_id_rmse,steady_iq_rmse, ...
    max(abs(T.rectangle_center_d_V)),max(abs(T.rectangle_center_q_V)), ...
    sqrt(mean(T.Fd_residual.^2)),sqrt(mean(T.Fq_residual.^2)),string(strategy), ...
    nnz(~T.selected_legal),nnz(~T.original_legal),nnz(T.negative_duration_selected),fallback_cycles, ...
    fallback_cycles/height(T),max_fallback,pred_d_rate,pred_q_rate,actual_d_rate,actual_q_rate, ...
    mean(exec),percentile(exec,95),max(exec),mean(T.feasibility_layer_time_s(first_timed:end)), ...
    mean(T.target_offset_ab_V), ...
    max(T.target_offset_ab_V),mean(T.layer_modified), ...
    'VariableNames',{'run_id','scenario','speed_rpm','id_ref_A','iq_ref_A', ...
    'motor_model','dc_bus_V', ...
    'voltage_vector_scale','active_vector_magnitude_V','reference_ramp_s', ...
    'sampling_period_s','Ld_H','Lq_H','alpha_mode','F_estimator', ...
    'completed_0p2s','illegal','first_illegal_time_s','first_selected_illegal_time_s', ...
    'minimum_d0','maximum_voltage_utilization_ratio','maximum_reference_voltage_V', ...
    'maximum_hex_exceedance_V','id_rmse_A','iq_rmse_A','steady_thd_percent', ...
    'torque_mean_Nm','torque_ripple_Nm','switching_actions','trace_rows', ...
    'steady_maximum_utilization_ratio','steady_negative_d0', ...
    'steady_id_rmse_A','steady_iq_rmse_A','peak_abs_rectangle_center_d_V', ...
    'peak_abs_rectangle_center_q_V','Fd_residual_rmse','Fq_residual_rmse', ...
    'strategy','illegal_command_count','original_illegal_command_count', ...
    'negative_duration_count','fallback_cycles','fallback_fraction', ...
    'max_consecutive_fallback_cycles','predicted_d_constraint_satisfaction_rate', ...
    'predicted_q_constraint_satisfaction_rate','actual_d_constraint_violation_rate', ...
    'actual_q_constraint_violation_rate','execution_time_average_s', ...
    'execution_time_p95_s','execution_time_max_s','feasibility_layer_time_average_s', ...
    'target_offset_average_V', ...
    'target_offset_maximum_V','modified_command_fraction'});
end

function value=percentile(x,p)
x=sort(x(isfinite(x)));if isempty(x),value=NaN;return;end
position=1+(numel(x)-1)*p/100;lo=floor(position);hi=ceil(position);
if lo==hi,value=x(lo);else,value=x(lo)+(position-lo)*(x(hi)-x(lo));end
end

function [u,F]=equilibrium_and_F(i,omega,m)
u=[m.Rs_Ohm*i(1)-omega*m.Lq_H*i(2); ...
    m.Rs_Ohm*i(2)+omega*(m.Ld_H*i(1)+m.psi_f_Wb)];
F=[-m.Rs_Ohm/m.Ld_H*i(1)+omega*m.Lq_H/m.Ld_H*i(2); ...
    -m.Rs_Ohm/m.Lq_H*i(2)-omega*m.Ld_H/m.Lq_H*i(1)-omega*m.psi_f_Wb/m.Lq_H];
end

function d=three_duties(command)
d=[NaN NaN NaN];
if isfield(command,'duties')
    value=command.duties(:).'; d(1:min(3,numel(value)))=value(1:min(3,numel(value)));
end
end

function value=field_or(s,name,default_value)
if isfield(s,name),value=s.(name);else,value=default_value;end
end
