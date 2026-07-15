function simulation = run_robust_case(project,scenario,method,bound_model,oracle_bound)
%RUN_ROBUST_CASE Feasibility control with causal independent-dq tightening.
% The copied controller and modulation functions are called without changes.
% An illegal applied command terminates integration only after its complete
% diagnostic row has been retained.

arguments
    project struct
    scenario struct
    method (1,1) string {mustBeMember(method,["C0_original_feasibility_control", ...
        "C1_global_robust_tightening","C2_scheduled_robust_tightening", ...
        "C3_offline_oracle_tightening"])} = "C0_original_feasibility_control"
    bound_model struct = struct('method',"E0_no_tightening")
    oracle_bound struct = struct()
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
rng(field_or(scenario,'random_seed',project.base.random_seed),'twister');
measurement_noise_std=field_or(scenario,'measurement_noise_std_A',0);
angle_error_rad=deg2rad(field_or(scenario,'angle_error_deg',0));
dead_time_s=field_or(scenario,'dead_time_s',0);
voltage_drop_V=field_or(scenario,'voltage_drop_V',0);
steady_init=logical(field_or(scenario,'diagnostic_steady_initialization',false));
if steady_init
    state=[scenario.id_ref_A;scenario.iq_ref_A;scenario.theta0_rad];
else
    state=[scenario.id0_A;scenario.iq0_A;scenario.theta0_rad];
end
measured_current=state(1:2)+measurement_noise_std*randn(2,1);
previous_current=measured_current;

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
current_history=repmat(measured_current,1,history_N+1);
applied_history=repmat(last_applied_voltage_dq,1,history_N);

names=["t_s","id_ref_A","iq_ref_A","id_A","iq_A","id_error_A","iq_error_A", ...
    "id_pred_k2_A","iq_pred_k2_A", ...
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
    "switching_actions_selected","original_switching_actions_selected", ...
    "epsilon_d_A","epsilon_q_A","robust_half_width_d_A","robust_half_width_q_A", ...
    "Jd_rob_limit_A2","Jq_rob_limit_A2","robust_bound_exceeds_tolerance", ...
    "constraint_certificate","tightened_rectangle_area_ratio", ...
    "R_H_nonempty","S2_used","S3_used","bound_execution_time_s", ...
    "tightening_execution_time_s","geometry_execution_time_s", ...
    "measured_id_A","measured_iq_A","measurement_noise_d_A", ...
    "measurement_noise_q_A","controller_theta_rad","reference_ramp_rate_A_s", ...
    "aligned_actual_d_violation","aligned_actual_q_violation", ...
    "aligned_joint_actual_violation","false_safe"];
D=struct();
for name=names, D.(name)=NaN(steps,1); end
selected_sequence_ids=strings(steps,1);selected_sequence_durations=strings(steps,1);
applied_sequence_ids=strings(steps,1);applied_sequence_durations=strings(steps,1);
original_sequence_ids=strings(steps,1);original_sequence_durations=strings(steps,1);

illegal_event=struct('occurred',false,'selected_time_s',NaN,'applied_time_s',NaN, ...
    'duties',[NaN NaN NaN],'reference_ab_V',[NaN NaN],'case_id',NaN);
selected_illegal_time=NaN;
completed=false;
executed=0;
fallback_streak=0;
previous_reference=[0;0];previous_feature_case=NaN;previous_feature_sector=NaN;
previous_command_signature="";
for k=1:steps
    t=(k-1)*Ts;
    profile=string(field_or(scenario,'profile_type',field_or(scenario,'reference_profile',"ramp")));
    if steady_init || profile=="constant"
        ramp=1;
        reference_dq=[scenario.id_ref_A;scenario.iq_ref_A];
    elseif profile=="two_step"
        if t<field_or(scenario,'current_step_time_s',.05)
            ramp=min(1,t/max(scenario.reference_ramp_s,eps));
            reference_dq=.5*[scenario.id_ref_A;scenario.iq_ref_A]*ramp;
        else
            ramp=1;reference_dq=[scenario.id_ref_A;scenario.iq_ref_A];
        end
    else
        ramp=min(1,t/max(scenario.reference_ramp_s,eps));
        reference_dq=[scenario.id_ref_A;scenario.iq_ref_A]*ramp;
    end
    current_dq=state(1:2);
    controller_theta=state(3)+angle_error_rad;
    input=struct('current_dq',measured_current,'previous_current_dq',previous_current, ...
        'last_applied_voltage_dq',last_applied_voltage_dq, ...
        'pending_voltage_dq',applied_command.reference_dq_at_selection, ...
        'pending_command',applied_command,'omega_e',omega_e,'pending_vector_id',0, ...
        'estimator_history_valid',k>1,'reference_dq',reference_dq, ...
        'theta_e',controller_theta,'current_history_dq',current_history, ...
        'applied_history_dq',applied_history);
    total_timer=tic;
    bound_timer=tic;
    if method=="C2_scheduled_robust_tightening"
        provisional_core=zhou_ipmsm.controller.icf_mpc_step(input,cfg);
        [provisional,~]=zhou_feasibility.apply_feasibility_layer( ...
            provisional_core,input,cfg,"proposed_feasibility_aware");
    else
        provisional=[];
    end
    reference_rate=norm(reference_dq-previous_reference)/Ts;
    if method=="C0_original_feasibility_control"
        epsilon_d=0;epsilon_q=0;
    elseif method=="C3_offline_oracle_tightening"
        assert(isfield(oracle_bound,'epsilon_d_A')&&isfield(oracle_bound,'epsilon_q_A'), ...
            'ZhouRobust:OracleMissing','C3 requires an explicit noncausal oracle sequence.');
        epsilon_d=oracle_bound.epsilon_d_A(k);epsilon_q=oracle_bound.epsilon_q_A(k);
    else
        if isempty(provisional)
            provisional_core=zhou_ipmsm.controller.icf_mpc_step(input,cfg);
            [provisional,~]=zhou_feasibility.apply_feasibility_layer( ...
                provisional_core,input,cfg,"proposed_feasibility_aware");
        end
        feature=online_feature_row(k,omega_e,measured_current,reference_dq, ...
            reference_rate,provisional,previous_feature_case,previous_feature_sector, ...
            previous_command_signature,vectors);
        [epsilon_d,epsilon_q]=zhou_robust.predict_residual_bound(bound_model,feature);
        epsilon_d=epsilon_d(1);epsilon_q=epsilon_q(1);
    end
    bound_elapsed=toc(bound_timer);
    tightening_timer=tic;
    original_half=[sqrt(scenario.Jd_limit_A2);sqrt(scenario.Jq_limit_A2)];
    robust_half=max(0,original_half-[epsilon_d;epsilon_q]);
    robust_cfg=cfg;robust_cfg.Jd_limit=robust_half(1)^2;robust_cfg.Jq_limit=robust_half(2)^2;
    tightening_elapsed=toc(tightening_timer);
    core_control=zhou_ipmsm.controller.icf_mpc_step(input,robust_cfg);
    geometry_timer=tic;
    [control,layer]=zhou_feasibility.apply_feasibility_layer( ...
        core_control,input,robust_cfg,"proposed_feasibility_aware");
    geometry_elapsed=toc(geometry_timer);
    controller_elapsed=toc(total_timer);
    selected=control.command;
    selected_feas=zhou_feasibility.voltage_feasibility( ...
        selected.reference_ab_V,vectors,selected,a.duty_tolerance);
    applied_feas=zhou_feasibility.voltage_feasibility( ...
        applied_command.reference_ab_V,vectors,applied_command,a.duty_tolerance);
    [~,Ftrue]=equilibrium_and_F(current_dq,omega_e,plant_paper);
    torque=zhou_ipmsm.model.electromagnetic_torque(current_dq,plant_paper);
    rect=control.geometry.rect;
    robust_intersection=zhou_feasibility.rectangle_hexagon_intersection( ...
        rect,vectors,a.voltage_tolerance_V);

    executed=k;
    D.t_s(k)=t; D.id_ref_A(k)=reference_dq(1); D.iq_ref_A(k)=reference_dq(2);
    D.id_A(k)=current_dq(1); D.iq_A(k)=current_dq(2);
    D.id_error_A(k)=reference_dq(1)-current_dq(1);
    D.iq_error_A(k)=reference_dq(2)-current_dq(2);
    D.id_pred_k2_A(k)=control.predicted_k2_dq(1);
    D.iq_pred_k2_A(k)=control.predicted_k2_dq(2);
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
    D.epsilon_d_A(k)=epsilon_d;D.epsilon_q_A(k)=epsilon_q;
    D.robust_half_width_d_A(k)=robust_half(1);D.robust_half_width_q_A(k)=robust_half(2);
    D.Jd_rob_limit_A2(k)=robust_cfg.Jd_limit;D.Jq_rob_limit_A2(k)=robust_cfg.Jq_limit;
    D.robust_bound_exceeds_tolerance(k)=epsilon_d>=original_half(1)||epsilon_q>=original_half(2);
    D.constraint_certificate(k)=control.constraint_satisfied_d&&control.constraint_satisfied_q&& ...
        ~D.robust_bound_exceeds_tolerance(k);
    D.tightened_rectangle_area_ratio(k)=(robust_half(1)/original_half(1))*(robust_half(2)/original_half(2));
    D.R_H_nonempty(k)=robust_intersection.nonempty;
    D.S3_used(k)=layer.fallback_used;D.S2_used(k)=layer.modified&&~layer.fallback_used;
    D.bound_execution_time_s(k)=bound_elapsed;D.tightening_execution_time_s(k)=tightening_elapsed;
    D.geometry_execution_time_s(k)=geometry_elapsed;
    D.measured_id_A(k)=measured_current(1);D.measured_iq_A(k)=measured_current(2);
    D.measurement_noise_d_A(k)=measured_current(1)-current_dq(1);
    D.measurement_noise_q_A(k)=measured_current(2)-current_dq(2);
    D.controller_theta_rad(k)=controller_theta;D.reference_ramp_rate_A_s(k)=reference_rate;
    selected_sequence_ids(k)=join(string(selected.sequence_vector_ids),';');
    selected_sequence_durations(k)=join(compose('%.17g',selected.sequence_durations_s),';');
    applied_sequence_ids(k)=join(string(applied_command.sequence_vector_ids),';');
    applied_sequence_durations(k)=join(compose('%.17g',applied_command.sequence_durations_s),';');
    original_sequence_ids(k)=join(string(core_control.command.sequence_vector_ids),';');
    original_sequence_durations(k)=join(compose('%.17g',core_control.command.sequence_durations_s),';');
    previous_feature_case=selected.case_id;
    previous_feature_sector=field_or(selected,'sector',selected_feas.sector);
    previous_command_signature=selected_sequence_ids(k)+"|"+selected_sequence_durations(k);
    previous_reference=reference_dq;

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

    delta_voltage_ab=[0,0];
    if dead_time_s>0
        [dead_delta,~]=zhou_ipmsm.inverter.deadtime_voltage_error(applied_command, ...
            current_dq,state(3),dc_bus,dead_time_s,Ts,a.deadtime_current_zero_tolerance_A);
        delta_voltage_ab=delta_voltage_ab+dead_delta;
    end
    if voltage_drop_V>0
        direction=applied_command.equivalent_ab_V;
        if norm(direction)>a.voltage_tolerance_V
            delta_voltage_ab=delta_voltage_ab-voltage_drop_V*direction/norm(direction);
        end
    end
    [next_state,applied_average_dq,audit]=zhou_ipmsm.model.integrate_command( ...
        state,applied_command,vectors,omega_e,plant_paper,Ts,a.time_tolerance_s, ...
        delta_voltage_ab,scenario.integration_step_s);
    D.integration_time_residual_s(k)=audit.time_residual_s;
    previous_current=measured_current;
    state=next_state;
    measured_current=state(1:2)+measurement_noise_std*randn(2,1);
    last_applied_voltage_dq=applied_average_dq;
    current_history=[current_history(:,2:end),measured_current];
    applied_history=[applied_history(:,2:end),applied_average_dq];
    applied_command=selected;
    if k==steps, completed=true; end
end

for j=1:max(0,executed-2)
    D.aligned_actual_d_violation(j)=abs(D.id_ref_A(j)-D.id_A(j+2))>sqrt(scenario.Jd_limit_A2)+1e-12;
    D.aligned_actual_q_violation(j)=abs(D.iq_ref_A(j)-D.iq_A(j+2))>sqrt(scenario.Jq_limit_A2)+1e-12;
    D.aligned_joint_actual_violation(j)=D.aligned_actual_d_violation(j)||D.aligned_actual_q_violation(j);
    D.false_safe(j)=D.constraint_certificate(j)&&D.aligned_joint_actual_violation(j);
end
for name=names, D.(name)=D.(name)(1:executed); end
trace=struct2table(D);
trace=addvars(trace,selected_sequence_ids(1:executed),selected_sequence_durations(1:executed), ...
    applied_sequence_ids(1:executed),applied_sequence_durations(1:executed), ...
    original_sequence_ids(1:executed),original_sequence_durations(1:executed), ...
    'NewVariableNames',{'selected_sequence_vector_ids','selected_sequence_durations_s', ...
    'applied_sequence_vector_ids','applied_sequence_durations_s', ...
    'original_sequence_vector_ids','original_sequence_durations_s'});
trace=addvars(trace,repmat(dc_bus,executed,1),repmat(scale,executed,1), ...
    repmat(dc_bus*scale,executed,1),repmat(scenario.reference_ramp_s,executed,1), ...
    repmat(Ts,executed,1),repmat(scenario.speed_rpm,executed,1), ...
    repmat(omega_e,executed,1),repmat(string(scenario.motor_model),executed,1), ...
    repmat(plant_paper.Ld_H,executed,1),repmat(plant_paper.Lq_H,executed,1), ...
    repmat(string(scenario.alpha_mode),executed,1), ...
    repmat(string(scenario.F_estimator),executed,1),repmat(method,executed,1), ...
    repmat(string(field_or(scenario,'scenario_id',scenario.name)),executed,1), ...
    repmat(string(field_or(scenario,'split',"unspecified")),executed,1), ...
    repmat(field_or(scenario,'random_seed',project.base.random_seed),executed,1), ...
    repmat(field_or(scenario,'plant_Ld_scale',1),executed,1), ...
    repmat(field_or(scenario,'plant_Lq_scale',1),executed,1), ...
    repmat(field_or(scenario,'plant_Rs_scale',1),executed,1), ...
    repmat(field_or(scenario,'plant_psi_f_scale',1),executed,1), ...
    repmat(measurement_noise_std,executed,1),repmat(angle_error_rad,executed,1), ...
    repmat(dead_time_s,executed,1),repmat(voltage_drop_V,executed,1), ...
    'NewVariableNames',{'dc_bus_V','voltage_vector_scale', ...
    'active_vector_magnitude_V','reference_ramp_s','sampling_period_s', ...
    'speed_rpm','omega_e_rad_s', ...
    'motor_model','Ld_H','Lq_H','alpha_mode','F_estimator','method', ...
    'scenario_id','data_split','random_seed','plant_Ld_scale','plant_Lq_scale', ...
    'plant_Rs_scale','plant_psi_f_scale','measurement_noise_std_A', ...
    'angle_error_rad','dead_time_s','voltage_drop_V'});
summary=summarize_trace(trace,scenario,project,dc_bus,scale,vectors,completed,illegal_event,plant_paper,method);
simulation=struct('scenario',scenario,'trace',trace,'summary',summary, ...
    'completed',completed,'illegal_event',illegal_event,'vectors',vectors, ...
    'plant_motor',plant_paper,'controller_motor',controller_paper, ...
    'bound_model',bound_model,'method',method, ...
    'runtime_assumptions',struct('dc_bus_V',dc_bus,'voltage_vector_scale',scale, ...
    'active_vector_magnitude_V',dc_bus*scale,'reference_ramp_s',scenario.reference_ramp_s, ...
    'sampling_period_s',Ts,'integration_step_s',scenario.integration_step_s));
end

function summary=summarize_trace(T,s,project,vdc,scale,vectors,completed,event,motor,method)
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
    sqrt(mean(T.Fd_residual.^2)),sqrt(mean(T.Fq_residual.^2)),string(method), ...
    nnz(~T.selected_legal),nnz(~T.original_legal),nnz(T.negative_duration_selected),fallback_cycles, ...
    fallback_cycles/height(T),max_fallback,pred_d_rate,pred_q_rate,actual_d_rate,actual_q_rate, ...
    mean(exec),percentile(exec,95),max(exec),mean(T.feasibility_layer_time_s(first_timed:end)), ...
    mean(T.target_offset_ab_V), ...
    max(T.target_offset_ab_V),mean(T.layer_modified), ...
    mean(T.aligned_actual_d_violation,'omitnan'),mean(T.aligned_actual_q_violation,'omitnan'), ...
    mean(T.aligned_joint_actual_violation,'omitnan'),mean(T.false_safe,'omitnan'), ...
    mean(T.constraint_certificate),mean(T.epsilon_d_A),mean(T.epsilon_q_A), ...
    percentile(T.epsilon_d_A,95),percentile(T.epsilon_q_A,95), ...
    max(T.epsilon_d_A),max(T.epsilon_q_A),mean(T.tightened_rectangle_area_ratio), ...
    mean(T.R_H_nonempty),mean(T.S2_used),mean(T.S3_used), ...
    max(T.fallback_consecutive_cycles),mean(T.robust_bound_exceeds_tolerance), ...
    mean(T.bound_execution_time_s(first_timed:end)), ...
    mean(T.tightening_execution_time_s(first_timed:end)), ...
    mean(T.geometry_execution_time_s(first_timed:end)), ...
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
    'method','illegal_command_count','original_illegal_command_count', ...
    'negative_duration_count','fallback_cycles','fallback_fraction', ...
    'max_consecutive_fallback_cycles','predicted_d_constraint_satisfaction_rate', ...
    'predicted_q_constraint_satisfaction_rate','actual_d_constraint_violation_rate', ...
    'actual_q_constraint_violation_rate','execution_time_average_s', ...
    'execution_time_p95_s','execution_time_max_s','feasibility_layer_time_average_s', ...
    'target_offset_average_V', ...
    'target_offset_maximum_V','modified_command_fraction', ...
    'aligned_actual_d_violation_rate','aligned_actual_q_violation_rate', ...
    'aligned_joint_actual_violation_rate','false_safe_rate','certification_rate', ...
    'epsilon_d_mean_A','epsilon_q_mean_A','epsilon_d_p95_A','epsilon_q_p95_A', ...
    'epsilon_d_max_A','epsilon_q_max_A','tightened_rectangle_area_ratio_mean', ...
    'R_H_nonempty_ratio','S2_ratio','S3_ratio','maximum_consecutive_S3_cycles', ...
    'robust_bound_exceeds_tolerance_rate','bound_execution_time_average_s', ...
    'tightening_execution_time_average_s','geometry_execution_time_average_s'});
end

function value=percentile(x,p)
x=sort(x(isfinite(x)));if isempty(x),value=NaN;return;end
position=1+(numel(x)-1)*p/100;lo=floor(position);hi=ceil(position);
if lo==hi,value=x(lo);else,value=x(lo)+(position-lo)*(x(hi)-x(lo));end
end

function T=online_feature_row(k,omega,current,reference,reference_rate,control, ...
        previous_case,previous_sector,previous_signature,vectors)
command=control.command;rect=control.geometry.rect;
vf=zhou_feasibility.voltage_feasibility(command.reference_ab_V,vectors,command,1e-12);
case_id=command.case_id;sector=field_or(command,'sector',vf.sector);
signature=join(string(command.sequence_vector_ids),';')+"|"+ ...
    join(compose('%.17g',command.sequence_durations_s),';');
sector_transition=isfinite(previous_sector)&&sector~=previous_sector;
case_transition=isfinite(previous_case)&&case_id~=previous_case;
command_transition=strlength(previous_signature)>0&&signature~=previous_signature;
feature_snapshot_index=k;prediction_index=k;selected_index=k;pending_index=k+1;
applied_index=k+1;actual_index=k+2;
omega_e_rad_s=omega;id_A=current(1);iq_A=current(2);id_ref_A=reference(1);iq_ref_A=reference(2);
abs_id_error_A=abs(reference(1)-current(1));abs_iq_error_A=abs(reference(2)-current(2));
Fd_hat=control.Fhat_dq(1);Fq_hat=control.Fhat_dq(2);
alpha_d=control.geometry.rect.alpha_d;alpha_q=control.geometry.rect.alpha_q;
voltage_utilization=vf.utilization_ratio;minimum_duty=min(command.duties);
rectangle_center_d_V=rect.center_dq(1);rectangle_center_q_V=rect.center_dq(2);
rectangle_half_d_V=rect.half_dq(1);rectangle_half_q_V=rect.half_dq(2);
reference_ramp_rate_A_s=reference_rate;
T=table(feature_snapshot_index,prediction_index,selected_index,pending_index, ...
    applied_index,actual_index,omega_e_rad_s,id_A,iq_A,id_ref_A,iq_ref_A, ...
    abs_id_error_A,abs_iq_error_A,Fd_hat,Fq_hat,alpha_d,alpha_q,case_id,sector, ...
    sector_transition,case_transition,command_transition,voltage_utilization, ...
    minimum_duty,rectangle_center_d_V,rectangle_center_q_V,rectangle_half_d_V, ...
    rectangle_half_q_V,reference_ramp_rate_A_s);
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
