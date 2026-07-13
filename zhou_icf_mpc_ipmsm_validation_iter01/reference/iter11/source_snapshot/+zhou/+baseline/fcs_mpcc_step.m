function output = fcs_mpcc_step(input, cfg)
%FCS_MPCC_STEP Traditional one-vector FCS-MPCC comparison baseline.

alpha = [cfg.paper.alpha_d; cfg.paper.alpha_q];
if cfg.assumptions.estimator=="fliess_join_2013_algebraic_integral"
    Fhat=zhou.controller.estimate_F_algebraic(input.current_history_dq, ...
        input.applied_history_dq,alpha,cfg.paper.Ts_s);
else
    Fhat = zhou.controller.estimate_F(input.current_dq, ...
        input.previous_current_dq, input.last_applied_voltage_dq, alpha, ...
        cfg.paper.Ts_s, input.estimator_history_valid, ...
        cfg.assumptions.estimator_initial_F_dq(:));
end
predicted_k1 = zhou.controller.predict_k1(input.current_dq, Fhat, ...
    input.pending_voltage_dq, alpha, cfg.paper.Ts_s);

candidate_cost = zeros(7, 1);
candidate_Jd = zeros(7, 1);
candidate_Jq = zeros(7, 1);
candidate_prediction = zeros(7, 2);
for vector_id = 0:6
    voltage_dq = zhou.math.park(cfg.vectors.ab_V(vector_id + 1, :), input.theta_e);
    predicted_k2 = zhou.controller.predict_k2(predicted_k1, Fhat, ...
        voltage_dq, alpha, cfg.paper.Ts_s);
    [candidate_Jd(vector_id + 1), candidate_Jq(vector_id + 1)] = ...
        zhou.controller.independent_costs(input.reference_dq, predicted_k2);
    candidate_cost(vector_id + 1) = candidate_Jd(vector_id + 1) + ...
        candidate_Jq(vector_id + 1);
    candidate_prediction(vector_id + 1, :) = predicted_k2.';
end
[~, selected_index] = min(candidate_cost); % deterministic lowest-ID tie
selected_vector = selected_index - 1;
selected_ab = cfg.vectors.ab_V(selected_index, :);
selected_state = cfg.vectors.states(selected_index, :);
pending_state = cfg.vectors.states(input.pending_vector_id + 1, :);

command = struct();
command.case_id = 0;
command.reference_ab_V = selected_ab;
command.equivalent_ab_V = selected_ab;
command.reference_dq_at_selection = zhou.math.park(selected_ab, input.theta_e);
command.theta_at_selection = input.theta_e;
command.selected_vector = selected_vector;
command.active_vector_ids = selected_vector;
command.duties = [double(selected_vector == 0), double(selected_vector ~= 0), 0];
command.durations_s = cfg.paper.Ts_s;
command.sequence_vector_ids = selected_vector;
command.sequence_states = selected_state;
command.sequence_durations_s = cfg.paper.Ts_s;
command.deadtime_transition_from_state = pending_state;
command.deadtime_transition_to_state = selected_state;
command.switching_actions = sum(abs(selected_state - pending_state));
command.positive_duration_switching_actions = command.switching_actions;
command.legal = true;
command.assumption = "traditional_single_vector_FCS_baseline_A14";

output = struct();
output.command = command;
output.Fhat_dq = Fhat;
output.predicted_k1_dq = predicted_k1;
output.predicted_k2_dq = candidate_prediction(selected_index, :).';
output.V_dq = zhou.controller.compute_V_terms(input.reference_dq, ...
    predicted_k1, Fhat, cfg.paper.Ts_s);
output.Jd = candidate_Jd(selected_index);
output.Jq = candidate_Jq(selected_index);
output.constraint_satisfied_d = output.Jd <= cfg.Jd_limit + ...
    cfg.assumptions.constraint_tolerance;
output.constraint_satisfied_q = output.Jq <= cfg.Jq_limit + ...
    cfg.assumptions.constraint_tolerance;
output.geometry = struct();
output.cost_crosscheck_error = 0;
output.candidate_cost = candidate_cost;
end
