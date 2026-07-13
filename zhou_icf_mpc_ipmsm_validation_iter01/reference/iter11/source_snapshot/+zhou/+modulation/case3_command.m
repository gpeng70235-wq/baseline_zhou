function command = case3_command(reference_ab, Ts, vectors, sector_tolerance, duty_tolerance)
%CASE3_COMMAND Three-vector barycentric synthesis; paper-missing assumption.

arguments
    reference_ab (1,2) double {mustBeFinite}
    Ts (1,1) double {mustBePositive}
    vectors struct
    sector_tolerance (1,1) double {mustBeNonnegative} = 1e-12
    duty_tolerance (1,1) double {mustBeNonnegative} = 1e-12
end

[sector, boundary] = zhou.geometry.sector_of_point(reference_ab, sector_tolerance);
assert(sector >= 1 && sector <= 6, 'Zhou:Case3ZeroReference', ...
    'Case 3 reference cannot be the origin.');

low_by_sector = [1, 3, 3, 5, 5, 1];
high_by_sector = [2, 2, 4, 4, 6, 6];
low_id = low_by_sector(sector);
high_id = high_by_sector(sector);
A = [vectors.ab_V(low_id + 1, :).', vectors.ab_V(high_id + 1, :).'];
d = A \ reference_ab(:);
d0 = 1 - sum(d);
legal = all(d >= -duty_tolerance) && d0 >= -duty_tolerance && ...
    all(d <= 1 + duty_tolerance) && d0 <= 1 + duty_tolerance;

ids = [0, low_id, high_id, low_id, 0];
durations = [d0/2, d(1)/2, d(2), d(1)/2, d0/2] * Ts;
states = vectors.states(ids + 1, :);
equivalent = d(1)*vectors.ab_V(low_id + 1, :) + ...
    d(2)*vectors.ab_V(high_id + 1, :);

command = struct();
command.case_id = 3;
command.reference_ab_V = reference_ab;
command.selected_vector = NaN;
command.active_vector_ids = [low_id, high_id];
command.duties = [d0, d(1), d(2)];
command.durations_s = command.duties * Ts;
command.sequence_vector_ids = ids;
command.sequence_states = states;
command.sequence_durations_s = durations;
command.switching_actions = 4;
command.positive_duration_switching_actions = ...
    zhou.inverter.count_sequence_transitions(states(durations > 0, :));
command.equivalent_ab_V = equivalent;
command.legal = legal && all(durations >= -100*eps(Ts)) && ...
    abs(sum(durations) - Ts) <= 100*eps(Ts);
command.sector = sector;
command.sector_boundary = boundary;
command.assumption = "barycentric_three_vector_symmetric_DPWM_A03_A04";
end
