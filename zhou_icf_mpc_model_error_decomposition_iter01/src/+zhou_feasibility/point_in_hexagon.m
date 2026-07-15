function [inside,audit] = point_in_hexagon(point_ab,vectors,tolerance)
%POINT_IN_HEXAGON Test inverter feasibility from the hexagon half spaces.
% This routine is independent of command.legal and of duty synthesis.

arguments
    point_ab (1,2) double {mustBeFinite}
    vectors struct
    tolerance (1,1) double {mustBeFinite,mustBeNonnegative} = 1e-10
end

vertices = active_vertices_ccw(vectors);
n = size(vertices,1);
normals = zeros(n,2);
bounds = zeros(n,1);
slacks = zeros(n,1);
for k = 1:n
    j = mod(k,n)+1;
    edge = vertices(j,:)-vertices(k,:);
    edge_length = norm(edge);
    assert(edge_length>0,'ZhouFeasibility:DegenerateHexagon', ...
        'Adjacent active voltage vectors must be distinct.');
    % For counter-clockwise vertices, [ey,-ex] is the outward normal.
    normals(k,:) = [edge(2),-edge(1)]/edge_length;
    bounds(k) = dot(normals(k,:),vertices(k,:));
    slacks(k) = bounds(k)-dot(normals(k,:),point_ab);
end
inside = all(slacks>=-tolerance);

audit = struct();
audit.inside = inside;
audit.point_ab = point_ab;
audit.vertices_ab = vertices;
audit.outward_normals = normals;
audit.halfspace_bounds_V = bounds;
audit.halfspace_slacks_V = slacks;
audit.minimum_slack_V = min(slacks);
audit.maximum_halfspace_violation_V = max(0,-min(slacks));
audit.tolerance_V = tolerance;
end

function vertices = active_vertices_ccw(vectors)
assert(isfield(vectors,'ab_V') && size(vectors.ab_V,1)>=7 && ...
    size(vectors.ab_V,2)==2,'ZhouFeasibility:InvalidVectors', ...
    'vectors.ab_V must contain V0 through V6 as a 7-by-2 array.');
vertices = double(vectors.ab_V(2:7,:));
assert(all(isfinite(vertices),'all'),'ZhouFeasibility:InvalidVectors', ...
    'The six active voltage vectors must be finite.');
center = mean(vertices,1);
[~,order] = sort(mod(atan2(vertices(:,2)-center(2), ...
    vertices(:,1)-center(1)),2*pi));
vertices = vertices(order,:);
end
