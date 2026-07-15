function analysis = analyze_rectangle(rect, vectors, tolerance, sector_tolerance, duty_tolerance)
%ANALYZE_RECTANGLE Full Fig. 3 geometry, reference and dwell-time path.

arguments
    rect struct
    vectors struct
    tolerance (1,1) double {mustBeNonnegative} = rect.tolerance
    sector_tolerance (1,1) double {mustBeNonnegative} = 1e-12
    duty_tolerance (1,1) double {mustBeNonnegative} = 1e-12
end

classification = zhou_ipmsm.geometry.classify_case(rect, tolerance);
selection = struct();
midpoint = struct();

switch classification.case_id
    case 1
        command = zhou_ipmsm.modulation.case1_command(rect.Ts, vectors);
    case 2
        selection = zhou_ipmsm.geometry.select_savv( ...
            classification.line_hits, rect.center_ab, vectors, sector_tolerance);
        midpoint = zhou_ipmsm.geometry.case2_midpoint(rect, ...
            selection.vector_id, classification, tolerance);
        selected_active = vectors.ab_V(selection.vector_id + 1, :);
        signed_duty = dot(midpoint.midpoint_ab, selected_active) / ...
            dot(selected_active, selected_active);
        selection.original_vector_id = selection.vector_id;
        selection.phase_feasibility_flip = false;
        selection.signed_duty_before_phase_check = signed_duty;
        if signed_duty < -duty_tolerance
            % Table I chose the opposite phase on the correct AVV line.
            % Flip only within that same line so the SAVV actually crosses
            % the feasible set; this is the explicit A20 ambiguity policy.
            selection.vector_id = mod(selection.vector_id + 2, 6) + 1;
            selection.vector_name = vectors.names(selection.vector_id + 1);
            selection.phase_feasibility_flip = true;
            midpoint = zhou_ipmsm.geometry.case2_midpoint(rect, ...
                selection.vector_id, classification, tolerance);
        end
        command = zhou_ipmsm.modulation.case2_command(midpoint.midpoint_ab, ...
            selection.vector_id, rect.Ts, vectors, duty_tolerance);
    case 3
        command = zhou_ipmsm.modulation.case3_command( ...
            rect.center_ab(:).', rect.Ts, vectors, sector_tolerance, duty_tolerance);
end

reference_dq = zhou_ipmsm.math.park(command.reference_ab_V, rect.theta);
Jd = (rect.Vd - rect.alpha_d*rect.Ts*reference_dq(1))^2;
Jq = (rect.Vq - rect.alpha_q*rect.Ts*reference_dq(2))^2;
[reference_inside, reference_residual] = ...
    zhou_ipmsm.geometry.point_in_rectangle(command.reference_ab_V, rect, tolerance);

analysis = struct();
analysis.rect = rect;
analysis.classification = classification;
analysis.selection = selection;
analysis.midpoint = midpoint;
analysis.command = command;
analysis.Jd = Jd;
analysis.Jq = Jq;
analysis.reference_inside = reference_inside;
analysis.reference_residual = reference_residual;
analysis.constraint_satisfied = Jd <= rect.Jd_limit + tolerance && ...
    Jq <= rect.Jq_limit + tolerance;
end
