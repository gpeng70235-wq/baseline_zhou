function command = case1_command(Ts, vectors)
%CASE1_COMMAND Paper Case 1: apply only zero vector 000.

command = struct();
command.case_id = 1;
command.reference_ab_V = [0, 0];
command.selected_vector = 0;
command.active_vector_ids = [];
command.duties = [1, 0, 0]; % [zero, active1, active2]
command.durations_s = Ts;
command.sequence_vector_ids = 0;
command.sequence_states = vectors.states(1, :);
command.sequence_durations_s = Ts;
command.switching_actions = 0;
command.positive_duration_switching_actions = 0;
command.equivalent_ab_V = [0, 0];
command.legal = true;
command.assumption = "paper_explicit_000";
end
