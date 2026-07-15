function simulation = run_closed_loop(method, scenario, project)
%RUN_CLOSED_LOOP Fixed-speed IPMSM current-loop simulation with one-step delay.

arguments
    method (1,1) string {mustBeMember(method,["ICF_MPC","FCS_MPCC"])}
    scenario struct
    project struct
end

p = project.paper;
a = project.assumptions;
vectors = zhou_ipmsm.inverter.voltage_vectors(a.dc_bus_V, a.voltage_vector_scale);
controller_paper=p;
plant_paper=p;
if ~isfield(plant_paper,'Ld_H'), plant_paper.Ld_H=plant_paper.Ls_H; end
if ~isfield(plant_paper,'Lq_H'), plant_paper.Lq_H=plant_paper.Ls_H; end
if isfield(scenario,'motor_model') && string(scenario.motor_model)=="P0"
    plant_paper.Ld_H=plant_paper.Ls_H;
    plant_paper.Lq_H=plant_paper.Ls_H;
else
    plant_paper.Ld_H=plant_paper.Ld_H*field_or(scenario,'plant_Ld_scale',1);
    plant_paper.Lq_H=plant_paper.Lq_H*field_or(scenario,'plant_Lq_scale',1);
end
plant_paper.Rs_Ohm=plant_paper.Rs_Ohm*field_or(scenario,'plant_Rs_scale',1);
plant_paper.psi_f_Wb=plant_paper.psi_f_Wb*field_or(scenario,'plant_psi_f_scale',1);
if isfield(scenario,'controller_alpha_d')
    controller_paper.alpha_d=scenario.controller_alpha_d;
    controller_paper.alpha_q=scenario.controller_alpha_q;
elseif isfield(scenario,'alpha_mode') && string(scenario.alpha_mode)=="axis_specific"
    if isfield(scenario,'motor_model') && string(scenario.motor_model)=="P0"
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
cfg = struct('paper', controller_paper, 'assumptions', a, 'vectors', vectors, ...
    'Jd_limit', scenario.Jd_limit_A2, 'Jq_limit', scenario.Jq_limit_A2);

Ts = p.Ts_s;
steps = round(scenario.simulation_time_s / Ts);
time_s = (0:steps-1).' * Ts;
waveform_samples_per_cycle = round(Ts/a.waveform_sample_period_s);
assert(abs(waveform_samples_per_cycle*a.waveform_sample_period_s-Ts) <= ...
    a.time_tolerance_s,'ZhouIPMSM:WaveformGridMismatch', ...
    'waveform_sample_period_s must divide Ts exactly.');
waveform_count = steps*waveform_samples_per_cycle;
waveform_time_s = (0:waveform_count-1).' * a.waveform_sample_period_s;
omega_m = scenario.speed_rpm * 2*pi/60;
omega_e = p.pole_pairs * omega_m;

state = [scenario.id0_A; scenario.iq0_A; scenario.theta0_rad];
previous_current = state(1:2);
last_applied_voltage_dq = [0;0];
if a.preinitialize_fixed_speed_controller
    equilibrium_dq=[plant_paper.Rs_Ohm*state(1)-omega_e*plant_paper.Lq_H*state(2); ...
        plant_paper.Rs_Ohm*state(2)+omega_e*(plant_paper.Ld_H*state(1)+plant_paper.psi_f_Wb)];
    if plant_paper.Ld_H==plant_paper.Lq_H && plant_paper.Ld_H==plant_paper.Ls_H
        plant_F=[-plant_paper.Rs_Ohm/plant_paper.Ls_H*state(1)+omega_e*state(2); ...
            -plant_paper.Rs_Ohm/plant_paper.Ls_H*state(2)-omega_e*state(1)- ...
            omega_e*plant_paper.psi_f_Wb/plant_paper.Ls_H];
    else
        plant_F=[-plant_paper.Rs_Ohm/plant_paper.Ld_H*state(1)+ ...
            omega_e*plant_paper.Lq_H/plant_paper.Ld_H*state(2); ...
            -plant_paper.Rs_Ohm/plant_paper.Lq_H*state(2)- ...
            omega_e*plant_paper.Ld_H/plant_paper.Lq_H*state(1)- ...
            omega_e*plant_paper.psi_f_Wb/plant_paper.Lq_H];
    end
    controller_alpha=[controller_paper.alpha_d;controller_paper.alpha_q];
    initial_F=plant_F+([1/plant_paper.Ld_H;1/plant_paper.Lq_H]- ...
        controller_alpha).*equilibrium_dq;
    cfg.assumptions.estimator_initial_F_dq=initial_F.';
    equilibrium_ab=zhou_ipmsm.math.inv_park(equilibrium_dq,state(3)).';
    if norm(equilibrium_ab)<=a.voltage_tolerance_V
        pending=zhou_ipmsm.modulation.case1_command(Ts,vectors);
    else
        pending=zhou_ipmsm.modulation.case3_command(equilibrium_ab,Ts,vectors, ...
            a.sector_angle_tolerance_rad,a.duty_tolerance);
    end
    pending.case_id=0;
    pending.selected_vector=NaN;
    pending.reference_dq_at_selection=equilibrium_dq;
    pending.theta_at_selection=state(3);
    last_applied_voltage_dq=equilibrium_dq;
else
    pending = zhou_ipmsm.modulation.case1_command(Ts, vectors);
    pending.reference_dq_at_selection = [0;0];
    pending.theta_at_selection = state(3);
end
pending_vector_id = 0;
history_N=a.estimator_window_samples;
current_history=repmat(state(1:2),1,history_N+1);
applied_history=repmat(last_applied_voltage_dq,1,history_N);
eso_state=[];

id_A = zeros(steps,1); iq_A = id_A; theta_e_rad = id_A;
id_ref_A = id_A; iq_ref_A = id_A;
ia_A = id_A; ib_A = id_A; ic_A = id_A; torque_Nm = id_A;
Fhat_d = id_A; Fhat_q = id_A; id_pred_k1 = id_A; iq_pred_k1 = id_A;
id_pred_k2 = id_A; iq_pred_k2 = id_A; Vd = id_A; Vq = id_A;
Jd = id_A; Jq = id_A; rectangle_area_V2 = NaN(steps,1);
case_selected = NaN(steps,1); case_applied = NaN(steps,1);
selected_vector = NaN(steps,1); applied_vector = NaN(steps,1);
switching_actions_selected = zeros(steps,1);
switching_actions_applied = zeros(steps,1);
command_legal = false(steps,1); constraint_d_ok = false(steps,1);
constraint_q_ok = false(steps,1); controller_time_s = zeros(steps,1);
integration_time_residual_s = zeros(steps,1);
tiny_negative_dwell_count = zeros(steps,1);
table_I_correction = false(steps,1); table_I_fallback = false(steps,1);
table_II_mismatch = false(steps,1); table_II_fallback = false(steps,1);
phase_feasibility_flip = false(steps,1); degenerate_single_point = false(steps,1);
sequence_vector_ids = strings(steps,1);
sequence_durations_s = strings(steps,1);
sequence_states = strings(steps,1);
applied_sequence_vector_ids = strings(steps,1);
applied_sequence_durations_s = strings(steps,1);
applied_sequence_states = strings(steps,1);
pending_Ud = zeros(steps,1); pending_Uq = zeros(steps,1);
selected_Ud = zeros(steps,1); selected_Uq = zeros(steps,1);
geometry_theta = zeros(steps,1);
selected_min_duration_s = zeros(steps,1);
applied_min_duration_s = zeros(steps,1);
illegal_selected = false(steps,1); illegal_applied = false(steps,1);
waveform_endpoint_residual_A = zeros(steps,1);
waveform_id_A = zeros(waveform_count,1);
waveform_iq_A = zeros(waveform_count,1);
waveform_theta_e_rad = zeros(waveform_count,1);
deadtime_delta_alpha_V=zeros(steps,1);deadtime_delta_beta_V=zeros(steps,1);
deadtime_delta_d_V=zeros(steps,1);deadtime_delta_q_V=zeros(steps,1);
deadtime_adverse_events=zeros(steps,1);

for k = 1:steps
    t = time_s(k);
    if isfield(scenario,'reference_profile') && scenario.reference_profile=="constant"
        ramp=1;
    else
        ramp = min(1, t / max(scenario.reference_ramp_s, eps));
    end
    reference_dq = [scenario.id_ref_A; scenario.iq_ref_A] * ramp;
    current_dq = state(1:2);
    input = struct();
    input.current_dq = current_dq;
    input.previous_current_dq = previous_current;
    input.last_applied_voltage_dq = last_applied_voltage_dq;
    input.pending_voltage_dq = pending.reference_dq_at_selection;
    input.pending_command = pending;
    input.omega_e = omega_e;
    input.pending_vector_id = pending_vector_id;
    input.estimator_history_valid = k > 1;
    input.reference_dq = reference_dq;
    input.theta_e = state(3);
    input.current_history_dq=current_history;
    input.applied_history_dq=applied_history;
    if isfield(scenario,'F_estimator') && string(scenario.F_estimator)=="basic_ESO"
        eso_input_dq=zhou_ipmsm.controller.sequence_equivalent_dq_voltage( ...
            pending,vectors,state(3),omega_e,0,Ts,a.candidate_voltage_frame_mode);
        [F_override,eso_state]=basic_ESO_F(eso_state,current_dq, ...
            eso_input_dq,controller_alpha,Ts,scenario.eso_pole);
        input.Fhat_override_dq=F_override;
    end

    timer = tic;
    if method == "ICF_MPC"
        control = zhou_ipmsm.controller.icf_mpc_step(input, cfg);
    else
        control = zhou_ipmsm.baseline.fcs_mpcc_step(input, cfg);
    end
    controller_time_s(k) = toc(timer);

    id_A(k) = current_dq(1);
    iq_A(k) = current_dq(2);
    theta_e_rad(k) = state(3);
    id_ref_A(k) = reference_dq(1);
    iq_ref_A(k) = reference_dq(2);
    abc = zhou_ipmsm.model.phase_currents(current_dq, state(3));
    ia_A(k) = abc(1); ib_A(k) = abc(2); ic_A(k) = abc(3);
    torque_Nm(k) = zhou_ipmsm.model.electromagnetic_torque(current_dq, plant_paper);
    Fhat_d(k) = control.Fhat_dq(1); Fhat_q(k) = control.Fhat_dq(2);
    id_pred_k1(k) = control.predicted_k1_dq(1);
    iq_pred_k1(k) = control.predicted_k1_dq(2);
    id_pred_k2(k) = control.predicted_k2_dq(1);
    iq_pred_k2(k) = control.predicted_k2_dq(2);
    Vd(k) = control.V_dq(1); Vq(k) = control.V_dq(2);
    Jd(k) = control.Jd; Jq(k) = control.Jq;
    if method == "ICF_MPC"
        rectangle_area_V2(k) = control.geometry.rect.area_V2;
        if isfield(control.geometry.selection,'table_I_correction_used')
            table_I_correction(k)=control.geometry.selection.table_I_correction_used;
            table_I_fallback(k)=control.geometry.selection.fallback_used;
            phase_feasibility_flip(k)=control.geometry.selection.phase_feasibility_flip;
        end
        if isfield(control.geometry.midpoint,'table_II_valid')
            table_II_mismatch(k)=control.geometry.midpoint.table_II_evaluable && ...
                ~control.geometry.midpoint.table_II_matches_geometry;
            table_II_fallback(k)=~control.geometry.midpoint.table_II_valid;
            degenerate_single_point(k)=control.geometry.midpoint.degenerate_single_point;
        end
    end
    case_selected(k) = control.command.case_id;
    case_applied(k) = pending.case_id;
    selected_vector(k) = control.command.selected_vector;
    applied_vector(k) = pending.selected_vector;
    switching_actions_selected(k) = control.command.switching_actions;
    switching_actions_applied(k) = pending.switching_actions;
    command_legal(k) = control.command.legal;
    constraint_d_ok(k) = control.constraint_satisfied_d;
    constraint_q_ok(k) = control.constraint_satisfied_q;
    pending_Ud(k)=control.pending_voltage_dq_used(1);
    pending_Uq(k)=control.pending_voltage_dq_used(2);
    selected_Ud(k)=control.selected_voltage_dq_used(1);
    selected_Uq(k)=control.selected_voltage_dq_used(2);
    geometry_theta(k)=control.geometry_theta;
    selected_min_duration_s(k)=min(control.command.sequence_durations_s);
    applied_min_duration_s(k)=min(pending.sequence_durations_s);
    illegal_selected(k)=~control.command.legal;
    illegal_applied(k)=~pending.legal;
    sequence_vector_ids(k) = join(string(control.command.sequence_vector_ids), ';');
    sequence_durations_s(k) = join(compose('%.17g', ...
        control.command.sequence_durations_s), ';');
    state_tokens = compose('%d%d%d', control.command.sequence_states(:,1), ...
        control.command.sequence_states(:,2), control.command.sequence_states(:,3));
    sequence_states(k) = join(state_tokens, ';');
    applied_sequence_vector_ids(k)=join(string(pending.sequence_vector_ids),';');
    applied_sequence_durations_s(k)=join(compose('%.17g', ...
        pending.sequence_durations_s),';');
    applied_state_tokens=compose('%d%d%d',pending.sequence_states(:,1), ...
        pending.sequence_states(:,2),pending.sequence_states(:,3));
    applied_sequence_states(k)=join(applied_state_tokens,';');

    if ~pending.legal
        error('ZhouIPMSM:AppliedIllegalCommand', ...
            ['Scenario %s, method %s, t=%.9g s: pending Case %g has duties %s, ' ...
             'reference [%g,%g] V.'],string(scenario.name),method,t,pending.case_id, ...
            mat2str(pending.duties,17),pending.reference_ab_V(1),pending.reference_ab_V(2));
    end
    if a.inverter_disturbance_model=="paper_2us_average_deadtime_per_commutated_leg"
        [deadtime_delta_ab,deadtime_audit]=zhou_ipmsm.inverter.deadtime_voltage_error( ...
            pending,current_dq,state(3),a.dc_bus_V,plant_paper.dead_time_s,Ts, ...
            a.deadtime_current_zero_tolerance_A);
    else
        deadtime_delta_ab=[0,0];
        deadtime_audit=struct('adverse_count',[0,0,0]);
    end
    deadtime_delta_dq=zhou_ipmsm.math.park(deadtime_delta_ab,state(3));
    deadtime_delta_alpha_V(k)=deadtime_delta_ab(1);
    deadtime_delta_beta_V(k)=deadtime_delta_ab(2);
    deadtime_delta_d_V(k)=deadtime_delta_dq(1);
    deadtime_delta_q_V(k)=deadtime_delta_dq(2);
    deadtime_adverse_events(k)=sum(deadtime_audit.adverse_count);
    [waveform_states, waveform_audit] = zhou_ipmsm.model.sample_command_waveform( ...
        state,pending,vectors,omega_e,plant_paper,Ts,a.waveform_sample_period_s, ...
        a.time_tolerance_s,deadtime_delta_ab);
    waveform_rows = (k-1)*waveform_samples_per_cycle + ...
        (1:waveform_samples_per_cycle);
    waveform_id_A(waveform_rows) = waveform_states(1,1:end-1).';
    waveform_iq_A(waveform_rows) = waveform_states(2,1:end-1).';
    waveform_theta_e_rad(waveform_rows) = waveform_states(3,1:end-1).';
    [next_state, applied_average_dq, integration_audit] = ...
        zhou_ipmsm.model.integrate_command(state, pending, vectors, omega_e, plant_paper, ...
        Ts, a.time_tolerance_s,deadtime_delta_ab,field_or(scenario,'integration_step_s',Inf));
    waveform_endpoint_residual_A(k) = norm( ...
        waveform_audit.endpoint_state(1:2)-next_state(1:2));
    integration_time_residual_s(k) = integration_audit.time_residual_s;
    tiny_negative_dwell_count(k) = integration_audit.tiny_negative_count;
    previous_current = current_dq;
    state = next_state;
    last_applied_voltage_dq = applied_average_dq;
    current_history=[current_history(:,2:end),state(1:2)];
    applied_history=[applied_history(:,2:end),applied_average_dq];
    pending = control.command;
    if method == "FCS_MPCC"
        pending_vector_id = control.command.selected_vector;
    else
        pending_vector_id = 0;
    end
end

log = table(time_s, id_A, iq_A, id_ref_A, iq_ref_A, theta_e_rad, ...
    ia_A, ib_A, ic_A, torque_Nm, Fhat_d, Fhat_q, id_pred_k1, iq_pred_k1, ...
    id_pred_k2, iq_pred_k2, Vd, Vq, Jd, Jq, ...
    repmat(scenario.Jd_limit_A2,steps,1), repmat(scenario.Jq_limit_A2,steps,1), ...
    rectangle_area_V2, case_selected, case_applied, selected_vector, ...
    applied_vector, switching_actions_selected, switching_actions_applied, ...
    command_legal, constraint_d_ok, constraint_q_ok, controller_time_s, ...
    integration_time_residual_s, tiny_negative_dwell_count, ...
    table_I_correction, table_I_fallback, table_II_mismatch, table_II_fallback, ...
    phase_feasibility_flip, degenerate_single_point, ...
    waveform_endpoint_residual_A,deadtime_delta_alpha_V,deadtime_delta_beta_V, ...
    deadtime_delta_d_V,deadtime_delta_q_V,deadtime_adverse_events, ...
    sequence_vector_ids, ...
    sequence_durations_s, sequence_states, applied_sequence_vector_ids, ...
    applied_sequence_durations_s,applied_sequence_states,pending_Ud,pending_Uq, ...
    selected_Ud,selected_Uq,geometry_theta,selected_min_duration_s, ...
    applied_min_duration_s,illegal_selected,illegal_applied, ...
    'VariableNames', {'time_s','id_A','iq_A','id_ref_A','iq_ref_A', ...
    'theta_e_rad','ia_A','ib_A','ic_A','torque_Nm','Fhat_d','Fhat_q', ...
    'id_pred_k1','iq_pred_k1','id_pred_k2','iq_pred_k2','Vd','Vq', ...
    'Jd','Jq','Jd_limit','Jq_limit','rectangle_area_V2','case_selected', ...
    'case_applied','selected_vector','applied_vector', ...
    'switching_actions_selected','switching_actions_applied','command_legal', ...
    'constraint_d_ok','constraint_q_ok','controller_time_s', ...
    'integration_time_residual_s','tiny_negative_dwell_count', ...
    'table_I_correction','table_I_fallback','table_II_mismatch', ...
    'table_II_fallback','phase_feasibility_flip','degenerate_single_point', ...
    'waveform_endpoint_residual_A', ...
    'deadtime_delta_alpha_V','deadtime_delta_beta_V','deadtime_delta_d_V', ...
    'deadtime_delta_q_V','deadtime_adverse_events', ...
    'sequence_vector_ids','sequence_durations_s','sequence_states', ...
    'applied_sequence_vector_ids','applied_sequence_durations_s', ...
    'applied_sequence_states','U3d_V','U3q_V','U4d_V','U4q_V', ...
    'geometry_theta_rad','selected_min_duration_s','applied_min_duration_s', ...
    'illegal_selected','illegal_applied'});

assert(all(command_legal), 'ZhouIPMSM:ClosedLoopIllegalCommand', ...
    '%s generated %d illegal commands.', method, nnz(~command_legal));
assert(max(integration_time_residual_s) <= a.time_tolerance_s, ...
    'ZhouIPMSM:IntegrationTimeFailure', 'Piecewise integration time mismatch.');
assert(max(waveform_endpoint_residual_A) <= a.waveform_endpoint_tolerance_A, ...
    'ZhouIPMSM:WaveformObserverDivergence', ...
    'Read-only waveform observer endpoint diverged from cycle plant state.');

cos_theta = cos(waveform_theta_e_rad);
sin_theta = sin(waveform_theta_e_rad);
waveform_alpha_A = cos_theta.*waveform_id_A-sin_theta.*waveform_iq_A;
waveform_beta_A = sin_theta.*waveform_id_A+cos_theta.*waveform_iq_A;
waveform_ia_A = waveform_alpha_A;
waveform_ib_A = -0.5*waveform_alpha_A+sqrt(3)/2*waveform_beta_A;
waveform_ic_A = -0.5*waveform_alpha_A-sqrt(3)/2*waveform_beta_A;
waveform_torque_Nm = zhou_ipmsm.model.electromagnetic_torque( ...
    [waveform_id_A waveform_iq_A],plant_paper);
waveform = table(waveform_time_s,waveform_id_A,waveform_iq_A, ...
    waveform_theta_e_rad,waveform_ia_A,waveform_ib_A,waveform_ic_A, ...
    waveform_torque_Nm,'VariableNames',{'time_s','id_A','iq_A', ...
    'theta_e_rad','ia_A','ib_A','ic_A','torque_Nm'});

simulation = struct();
simulation.method = method;
simulation.scenario = scenario;
simulation.log = log;
simulation.waveform = waveform;
simulation.omega_e_rad_s = omega_e;
simulation.electrical_frequency_Hz = omega_e/(2*pi);
simulation.vectors = vectors;
simulation.final_state = state;
simulation.plant_motor = plant_paper;
simulation.controller_motor = controller_paper;
end

function value=field_or(s,name,default_value)
if isfield(s,name), value=s.(name); else, value=default_value; end
end
