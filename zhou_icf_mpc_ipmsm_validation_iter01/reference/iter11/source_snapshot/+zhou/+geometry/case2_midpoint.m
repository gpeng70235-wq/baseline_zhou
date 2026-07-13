function result = case2_midpoint(rect, selected_vector, classification, tolerance)
%CASE2_MIDPOINT Paper Table II and equation (14), cross-checked geometrically.

arguments
    rect struct
    selected_vector (1,1) double {mustBeInteger, mustBeInRange(selected_vector, 1, 6)}
    classification struct
    tolerance (1,1) double {mustBeNonnegative} = rect.tolerance
end

signature = zhou.geometry.line_side_signature(rect, selected_vector, tolerance);
line_id = signature.line_id;
intersection = classification.intersections(line_id);
point_count = size(intersection.points_ab, 1);
assert(intersection.hit && ismember(point_count, [1, 2]), ...
    'Zhou:Case2IntersectionFailure', ...
    'Selected AVV line must have a one- or two-point feasible segment.');
geometric_midpoint = mean(intersection.points_ab, 1);

theta = rect.theta;
T = rect.Ts;
ad = rect.alpha_d;
aq = rect.alpha_q;
D = [2*T*ad*cos(theta), ...
     4*T*ad*sin(pi/6 + theta), ...
     4*T*ad*sin(pi/6 - theta)];
Q = [2*T*aq*sin(theta), ...
     4*T*aq*sin(pi/3 - theta), ...
     4*T*aq*sin(pi/3 + theta)];

analytic_valid = point_count == 2 && ismember(signature.K, [1, 2, 3]);
ua = NaN;
N1 = NaN;
N2 = NaN;
formula_branch = "invalid_or_degenerate";

table_II_matches_geometry = false;
if analytic_valid
    if ismember(signature.K, [1, 3])
        exponent = (signature.K - 1) / 2;
        N1 = (-1)^exponent * ...
            (2 * (signature.sym(3) + signature.sym(4)) - signature.K);
        N2 = (-1)^exponent * ...
            (2 * (signature.sym(2) + signature.sym(4)) - signature.K);
        analytic_valid = abs(D(line_id)) > tolerance && ...
            abs(Q(line_id)) > tolerance;
        if analytic_valid
            ua = (rect.Vd + N1*rect.sqrt_Jd) / D(line_id) + ...
                 (rect.Vq + N2*rect.sqrt_Jq) / Q(line_id);
            formula_branch = "K_1_or_3";
        end
    else
        if signature.sym(1) == signature.sym(2)
            analytic_valid = abs(Q(line_id)) > tolerance;
            if analytic_valid
                signs = [-1, 1, -1];
                ua = signs(line_id) * rect.Vq / Q(line_id);
                formula_branch = "K_2_sym_a_equals_sym_b";
            end
        else
            analytic_valid = abs(D(line_id)) > tolerance;
            if analytic_valid
                ua = rect.Vd / D(line_id);
                formula_branch = "K_2_sym_a_not_equal_sym_b";
            end
        end
    end
end

table_II_evaluable = analytic_valid;
if analytic_valid
    switch line_id
        case 1
            ub = 0;
        case 2
            ub = sqrt(3) * ua;
        case 3
            ub = -sqrt(3) * ua;
    end
    table_II_midpoint = [ua, ub];
    discrepancy = norm(table_II_midpoint - geometric_midpoint);
    scale = max([1, norm(table_II_midpoint), norm(geometric_midpoint)]);
    table_II_matches_geometry = discrepancy <= 1e3*tolerance*scale;
    if table_II_matches_geometry
        midpoint = table_II_midpoint;
        method = "paper_Table_II";
    else
        % The prose unambiguously requires the segment midpoint. Printed
        % Table II has K=2 factor and K=1/3 sign inconsistencies (A19).
        midpoint = geometric_midpoint;
        method = "paper_prose_geometric_midpoint_due_to_Table_II_mismatch_A19";
    end
else
    table_II_midpoint = [NaN, NaN];
    discrepancy = NaN;
    midpoint = geometric_midpoint;
    method = "equivalent_geometric_fallback_for_singularity_A06";
end

result = struct();
result.midpoint_ab = midpoint;
result.geometric_midpoint_ab = geometric_midpoint;
result.table_II_midpoint_ab = table_II_midpoint;
result.table_II_evaluable = table_II_evaluable;
result.table_II_valid = analytic_valid && table_II_matches_geometry;
result.table_II_matches_geometry = table_II_matches_geometry;
result.table_II_discrepancy_V = discrepancy;
result.method = method;
result.formula_branch = formula_branch;
result.signature = signature;
result.D = D;
result.Q = Q;
result.N1 = N1;
result.N2 = N2;
result.intersection = intersection;
result.intersection_point_count = point_count;
result.degenerate_single_point = point_count == 1;
end
