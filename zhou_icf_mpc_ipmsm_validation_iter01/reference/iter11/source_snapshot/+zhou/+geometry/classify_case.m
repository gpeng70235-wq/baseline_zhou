function classification = classify_case(rect, tolerance)
%CLASSIFY_CASE Paper Fig. 3 Case 1/2/3 decision flow.

arguments
    rect struct
    tolerance (1,1) double {mustBeNonnegative} = rect.tolerance
end

[origin_inside, origin_residual] = ...
    zhou.geometry.point_in_rectangle([0, 0], rect, tolerance);
first_intersection = zhou.geometry.line_rectangle_intersections( ...
    rect, 1, tolerance);
intersections = repmat(first_intersection, 3, 1);
intersections(1) = first_intersection;
line_hits = false(1, 3);
line_hits(1) = first_intersection.hit;
for line_id = 2:3
    intersections(line_id) = ...
        zhou.geometry.line_rectangle_intersections(rect, line_id, tolerance);
    line_hits(line_id) = intersections(line_id).hit;
end

if origin_inside
    case_id = 1;
elseif any(line_hits)
    case_id = 2;
else
    case_id = 3;
end

classification = struct();
classification.case_id = case_id;
classification.origin_inside = origin_inside;
classification.origin_residual = origin_residual;
classification.line_hits = line_hits;
classification.intersections = intersections;
classification.eq12_interpretation = ...
    "geometric_sign_change_due_to_XOR_contradiction_A05";
end
