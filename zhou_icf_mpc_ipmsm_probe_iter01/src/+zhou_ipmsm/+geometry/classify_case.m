function classification = classify_case(rect, tolerance)
%CLASSIFY_CASE Preserve the Iteration 11 Case 1/2/3 decision geometry.

if nargin < 2
    tolerance = rect.tolerance;
end
origin_residual = abs(-rect.center_dq) - rect.half_dq;
origin_inside = all(origin_residual <= tolerance);
line_angles = [0 pi/3 2*pi/3];
intersections = repmat(zhou_ipmsm.geometry.calculate_intersections( ...
    rect,line_angles(1),tolerance),1,3);
line_hits = false(1,3);
for line_id = 1:3
    intersections(line_id) = zhou_ipmsm.geometry.calculate_intersections( ...
        rect,line_angles(line_id),tolerance);
    line_hits(line_id) = intersections(line_id).hit;
end

if origin_inside
    case_id = 1;
elseif any(line_hits)
    case_id = 2;
else
    case_id = 3;
end
classification = struct('case_id',case_id,'origin_inside',origin_inside, ...
    'origin_residual',max(origin_residual),'line_hits',line_hits, ...
    'line_angles_rad',line_angles,'intersections',intersections);
end
