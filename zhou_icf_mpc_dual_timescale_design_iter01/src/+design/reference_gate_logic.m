function [gate,diagnostic] = reference_gate_logic(obs,cfg)
%REFERENCE_GATE_LOGIC Reference only; not connected to the Zhou controller.
% Current native-decision information produces decision_gate_next. The
% predictor consumes the previously latched gate, preventing an algebraic
% loop between prediction, native selection, and trend enabling.

arguments
    obs struct
    cfg struct = design.project_parameter()
end

required = {'u_hp_dq_V','window_energy_dq_V2','regressor_rcond_dq', ...
    'residual_jump_dq_A_per_s','zero_vector_run','history_valid', ...
    'slow_tick','s2','decision'};
for k = 1:numel(required)
    assert(isfield(obs,required{k}),'DualTimescale:MissingGateInput', ...
        'Missing gate input %s.',required{k});
end

u_hp = obs.u_hp_dq_V(:);
energy = obs.window_energy_dq_V2(:);
rcond_value = obs.regressor_rcond_dq(:);
residual_jump = abs(obs.residual_jump_dq_A_per_s(:));
assert(numel(u_hp)==2 && numel(energy)==2 && numel(rcond_value)==2, ...
    'DualTimescale:GateDimension','Axis gate inputs must be 2-by-1.');

exc_amp = abs(u_hp) > cfg.u_hp_min_V;
exc_energy = energy > cfg.E_u_min_V2;
exc_condition = rcond_value >= cfg.regressor_rcond_min;
exc_nonzero = obs.zero_vector_run <= cfg.max_consecutive_zero_vectors;
exc_residual = residual_jump <= cfg.residual_jump_max_A_per_s;
g_exc = exc_amp & exc_energy & exc_condition & exc_nonzero & ...
    exc_residual & logical(obs.history_valid);

s2 = obs.s2;
s2_fields = {'triggered','reconstruction_valid','durations_valid', ...
    'log_complete','clipped_unknown','voltage_utilization_ratio'};
for k = 1:numel(s2_fields)
    assert(isfield(s2,s2_fields{k}),'DualTimescale:MissingS2Input', ...
        'Missing S2 quality input %s.',s2_fields{k});
end
g_s2 = logical(s2.reconstruction_valid) && logical(s2.durations_valid) && ...
    logical(s2.log_complete) && ~logical(s2.clipped_unknown) && ...
    isfinite(s2.voltage_utilization_ratio);
step_scale = 1;
if g_s2 && s2.voltage_utilization_ratio >= cfg.s2_high_utilization_ratio
    step_scale = cfg.s2_high_utilization_step_scale;
end

decision = obs.decision;
decision_fields = {'native_selection_valid','Jd_pred_A2','Jq_pred_A2', ...
    'Jd_limit_A2','Jq_limit_A2','mode_gap_A2'};
for k = 1:numel(decision_fields)
    assert(isfield(decision,decision_fields{k}), ...
        'DualTimescale:MissingDecisionInput', ...
        'Missing native-decision input %s.',decision_fields{k});
end
margins = [decision.Jd_limit_A2-decision.Jd_pred_A2; ...
    decision.Jq_limit_A2-decision.Jq_pred_A2];
m_J = min(margins);
near_safe_boundary = m_J >= 0 && m_J <= cfg.delta_J_A2;
near_mode_tie = abs(decision.mode_gap_A2) <= cfg.delta_mode_gap_A2;
decision_gate_next = logical(decision.native_selection_valid) && ...
    all(isfinite([margins;decision.mode_gap_A2])) && ...
    (near_safe_boundary || near_mode_tie);

gate = struct();
gate.g_exc_dq = g_exc;
gate.g_s2 = g_s2;
gate.alpha_step_scale = step_scale;
gate.g_alpha_dq = g_exc & g_s2 & logical(obs.slow_tick);
gate.g_F_dq = repmat(g_s2 && logical(obs.history_valid),2,1);
gate.g_decision_next = decision_gate_next;
gate.g_decision_latched = logical(field_or(obs,'decision_gate_latched',false));

reason = strings(2,1);
for axis = 1:2
    parts = strings(0,1);
    if ~obs.history_valid, parts(end+1)="history_invalid"; end %#ok<AGROW>
    if ~exc_amp(axis), parts(end+1)="hp_amplitude_low"; end %#ok<AGROW>
    if ~exc_energy(axis), parts(end+1)="window_energy_low"; end %#ok<AGROW>
    if ~exc_condition(axis), parts(end+1)="regressor_ill_conditioned"; end %#ok<AGROW>
    if ~exc_nonzero, parts(end+1)="zero_vector_stagnation"; end %#ok<AGROW>
    if ~exc_residual(axis), parts(end+1)="residual_jump"; end %#ok<AGROW>
    if ~g_s2, parts(end+1)="applied_voltage_untrusted"; end %#ok<AGROW>
    if ~obs.slow_tick, parts(end+1)="not_slow_tick"; end %#ok<AGROW>
    if isempty(parts), reason(axis)="update"; else, reason(axis)=join(parts,"|"); end
end
diagnostic = struct('alpha_reason_dq',reason,'margins_A2',margins, ...
    'm_J_A2',m_J,'near_safe_boundary',near_safe_boundary, ...
    'near_mode_tie',near_mode_tie,'s2_triggered',logical(s2.triggered), ...
    's2_trigger_did_not_force_freeze',logical(s2.triggered)&&g_s2);
end

function value = field_or(s,name,default_value)
if isfield(s,name), value=s.(name); else, value=default_value; end
end
