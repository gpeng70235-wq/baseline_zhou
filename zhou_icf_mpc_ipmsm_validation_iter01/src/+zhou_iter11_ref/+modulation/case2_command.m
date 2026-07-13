function command = case2_command(reference_ab, selected_vector, Ts, vectors, tolerance)
%CASE2_COMMAND SAVV+000 dwell times; missing in paper, assumption A03/A04.

arguments
    reference_ab (1,2) double {mustBeFinite}
    selected_vector (1,1) double {mustBeInteger, mustBeInRange(selected_vector, 1, 6)}
    Ts (1,1) double {mustBePositive}
    vectors struct
    tolerance (1,1) double {mustBeNonnegative} = 1e-12
end

active = vectors.ab_V(selected_vector + 1, :);
duty = dot(reference_ab, active) / dot(active, active);
collinearity = abs(active(1)*reference_ab(2) - active(2)*reference_ab(1));
scale = max(1, norm(active) * norm(reference_ab));
legal = duty >= -tolerance && duty <= 1 + tolerance && ...
    collinearity <= 1e3*tolerance*scale;

active_time = duty * Ts;
zero_time = Ts - active_time;
durations = [zero_time/2, active_time, zero_time/2];
ids = [0, selected_vector, 0];
states = vectors.states(ids + 1, :);

command = struct();
command.case_id = 2;
command.reference_ab_V = reference_ab;
command.selected_vector = selected_vector;
command.active_vector_ids = selected_vector;
command.duties = [1-duty, duty, 0];
command.durations_s = [zero_time, active_time];
command.sequence_vector_ids = ids;
command.sequence_states = states;
command.sequence_durations_s = durations;
command.switching_actions = 2 * sum(vectors.states(selected_vector + 1, :));
command.positive_duration_switching_actions = ...
    zhou_iter11_ref.inverter.count_sequence_transitions(states(durations > 0, :));
command.equivalent_ab_V = duty * active;
command.legal = legal && all(durations >= -100*eps(Ts)) && ...
    abs(sum(durations) - Ts) <= 100*eps(Ts);
command.collinearity_residual = collinearity;
command.assumption = "linear_SAVV_plus_000_and_symmetric_sequence_A03_A04";
end
