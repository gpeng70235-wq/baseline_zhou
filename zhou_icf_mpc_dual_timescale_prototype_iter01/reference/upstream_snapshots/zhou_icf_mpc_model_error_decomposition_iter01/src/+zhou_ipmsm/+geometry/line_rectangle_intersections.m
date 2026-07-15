function out = line_rectangle_intersections(rect, line_id, tolerance)
%LINE_RECTANGLE_INTERSECTIONS Intersect an equation-(10) AVV line and rectangle.
% This implements the prose meaning of equation (12), not standard XOR.

arguments
    rect struct
    line_id (1,1) double {mustBeInteger, mustBeInRange(line_id, 1, 3)}
    tolerance (1,1) double {mustBeNonnegative} = rect.tolerance
end

lines = zhou_ipmsm.geometry.active_lines();
normal = lines.coefficients(line_id, :);
normal = normal / norm(normal); % signed distance in volts for all three lines
direction = lines.directions(line_id, :);
poly = rect.polygon_ab;
points = zeros(0, 2);

for edge = 1:4
    p = poly(edge, :);
    q = poly(edge + 1, :);
    fp = dot(normal, p);
    fq = dot(normal, q);
    if abs(fp) <= tolerance
        points = add_unique(points, p, tolerance);
    end
    if abs(fq) <= tolerance
        points = add_unique(points, q, tolerance);
    end
    if fp * fq < -tolerance^2
        lambda = fp / (fp - fq);
        hit = p + lambda * (q - p);
        points = add_unique(points, hit, tolerance);
    elseif abs(fp) <= tolerance && abs(fq) <= tolerance
        points = add_unique(points, p, tolerance);
        points = add_unique(points, q, tolerance);
    end
end

corner_values = rect.corners_ab * normal.';
geometric_hit = min(corner_values) <= tolerance && ...
    max(corner_values) >= -tolerance;

if geometric_hit && isempty(points)
    error('ZhouIPMSM:IntersectionFailure', ...
        'Sign test reports a line hit but edge intersections are empty.');
end

if size(points, 1) > 2
    parameter = points * direction.';
    [~, i_min] = min(parameter);
    [~, i_max] = max(parameter);
    points = points([i_min, i_max], :);
end

if size(points, 1) == 2
    parameter = points * direction.';
    [parameter, order] = sort(parameter);
    points = points(order, :);
    midpoint = mean(points, 1);
else
    parameter = points * direction.';
    midpoint = points;
end

out = struct();
out.line_id = line_id;
out.hit = geometric_hit;
out.points_ab = points;
out.midpoint_ab = midpoint;
out.parameter = parameter;
out.corner_values = corner_values;
out.max_line_residual = 0;
if ~isempty(points)
    out.max_line_residual = max(abs(points * normal.'));
end
out.tangent = geometric_hit && size(points, 1) == 1;
end

function points = add_unique(points, candidate, tolerance)
if isempty(points) || all(vecnorm(points - candidate, 2, 2) > max(tolerance, eps))
    points(end + 1, :) = candidate; %#ok<AGROW>
end
end
