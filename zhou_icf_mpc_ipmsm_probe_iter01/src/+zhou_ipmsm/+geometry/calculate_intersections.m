function out = calculate_intersections(rect, line_angle, tolerance)
%CALCULATE_INTERSECTIONS Intersect an active-vector line with a rectangle.
% The line is infinite, passes through the origin, and is specified modulo pi.

if nargin < 3
    tolerance = rect.tolerance;
end
direction = [cos(line_angle) sin(line_angle)];
normal = [-direction(2) direction(1)];
polygon = rect.polygon_ab;
points = zeros(0,2);

for edge = 1:4
    p = polygon(edge,:);
    q = polygon(edge+1,:);
    fp = dot(normal,p);
    fq = dot(normal,q);
    if abs(fp) <= tolerance
        points = add_unique(points,p,tolerance);
    end
    if fp*fq < -tolerance^2
        fraction = fp/(fp-fq);
        points = add_unique(points,p + fraction*(q-p),tolerance);
    elseif abs(fp) <= tolerance && abs(fq) <= tolerance
        points = add_unique(points,q,tolerance);
    end
end

corner_values = rect.corners_ab * normal';
hit = min(corner_values) <= tolerance && max(corner_values) >= -tolerance;
if size(points,1) > 2
    parameter = points * direction';
    [~,lo] = min(parameter);
    [~,hi] = max(parameter);
    points = points([lo hi],:);
end
if ~isempty(points)
    [~,order] = sort(points * direction');
    points = points(order,:);
end

out = struct('angle_rad',line_angle,'hit',hit,'points_ab',points, ...
    'midpoint_ab',zeros(0,2),'tangent',size(points,1)==1, ...
    'max_line_residual_V',0);
if ~isempty(points)
    out.midpoint_ab = mean(points,1);
    out.max_line_residual_V = max(abs(points*normal'));
end
end

function points = add_unique(points, candidate, tolerance)
if isempty(points) || all(vecnorm(points-candidate,2,2) > max(tolerance,eps))
    points(end+1,:) = candidate; %#ok<AGROW>
end
end
