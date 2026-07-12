function command = generate_case_sequence(reference_ab, Ts, vectors, tolerance, forced_case, selected_vector)
%GENERATE_CASE_SEQUENCE Case 1/2/3 dwell-time synthesis.
% Case 1 uses 000, Case 2 uses symmetric 000-active-000, and Case 3
% uses the Iteration 11 symmetric five-segment two-active-vector sequence.

if nargin < 4
    tolerance = 1e-10;
end
reference_ab = reshape(reference_ab,1,[]);
assert(numel(reference_ab)==2 && all(isfinite(reference_ab)) && Ts>0, ...
    'ZhouIPMSM:InvalidSequenceInput','Reference and Ts must be finite and physical.');
if nargin < 5 || isempty(forced_case)
    if norm(reference_ab) <= tolerance
        forced_case = 1;
    else
        forced_case = 3;
    end
end
if nargin < 6
    selected_vector = [];
end

switch forced_case
    case 1
        ids = 0;
        durations = Ts;
        duties = [1 0 0];
        synthesized_reference = [0 0];
        requested_feasible = norm(reference_ab)<=tolerance;
    case 2
        if isempty(selected_vector)
            [active_id,duty] = closest_active_projection(reference_ab,vectors);
        else
            active_id = selected_vector;
            active = vectors.ab_V(active_id+1,:);
            duty = dot(reference_ab,active)/dot(active,active);
        end
        requested_duty = duty;
        active = vectors.ab_V(active_id+1,:);
        collinearity = abs(active(1)*reference_ab(2)-active(2)*reference_ab(1));
        collinearity_scale = max(1,norm(active)*norm(reference_ab));
        requested_feasible = requested_duty>=-tolerance && ...
            requested_duty<=1+tolerance && ...
            collinearity<=1e3*tolerance*collinearity_scale;
        duty = min(1,max(0,requested_duty));
        ids = [0 active_id 0];
        durations = [(1-duty)/2 duty (1-duty)/2]*Ts;
        duties = [1-duty duty 0];
        synthesized_reference = duty*vectors.ab_V(active_id+1,:);
    case 3
        angle = atan2(reference_ab(2),reference_ab(1));
        sector = mod(floor(mod(angle,2*pi)/(pi/3)),6)+1;
        lower_by_sector = [1 3 3 5 5 1];
        upper_by_sector = [2 2 4 4 6 6];
        lower_id = lower_by_sector(sector);
        upper_id = upper_by_sector(sector);
        active_vectors = [vectors.ab_V(lower_id+1,:)' vectors.ab_V(upper_id+1,:)'];
        active_duty = active_vectors\reference_ab(:);
        requested_active_duty = active_duty;
        requested_feasible = all(requested_active_duty>=-tolerance) && ...
            all(requested_active_duty<=1+tolerance) && ...
            sum(requested_active_duty)<=1+tolerance;
        active_duty(abs(active_duty)<=tolerance) = 0;
        active_duty = max(active_duty,0);
        active_sum = sum(active_duty);
        if active_sum > 1
            % Radial projection to the inverter hexagon keeps the command legal.
            active_duty = active_duty/active_sum;
            active_sum = 1;
        end
        zero_duty = 1-active_sum;
        ids = [0 lower_id upper_id lower_id 0];
        durations = [zero_duty/2 active_duty(1)/2 active_duty(2) ...
            active_duty(1)/2 zero_duty/2]*Ts;
        duties = [zero_duty active_duty'];
        synthesized_reference = active_duty(1)*vectors.ab_V(lower_id+1,:) + ...
            active_duty(2)*vectors.ab_V(upper_id+1,:);
    otherwise
        error('ZhouIPMSM:InvalidCase','Case id must be 1, 2, or 3.');
end

durations(abs(durations)<=max(tolerance*Ts,eps(Ts)*16)) = 0;
durations = max(durations,0);
durations = durations*(Ts/sum(durations));
command = struct();
command.case_id = forced_case;
command.requested_reference_ab_V = reference_ab;
command.reference_ab_V = synthesized_reference;
command.equivalent_ab_V = synthesized_reference;
command.sequence_vector_ids = ids;
command.sequence_durations_s = durations;
command.sequence_states = vectors.states(ids+1,:);
command.duties = duties;
command.requested_feasible = requested_feasible;
command.projection_error_V = norm(reference_ab-synthesized_reference);
command.saturation_used = command.projection_error_V>max(tolerance,1e-12);
command.sequence_legal = all(isfinite(durations)) && all(durations>=0) && ...
    abs(sum(durations)-Ts)<=max(tolerance,eps(Ts)*16) && ...
    all(ids>=0 & ids<=6);
command.legal = command.sequence_legal && requested_feasible;
end

function [active_id,duty] = closest_active_projection(reference_ab,vectors)
projection = vectors.ab_V(2:end,:)*reference_ab(:);
[~,active_id] = max(projection);
active = vectors.ab_V(active_id+1,:);
duty = dot(reference_ab,active)/dot(active,active);
end
