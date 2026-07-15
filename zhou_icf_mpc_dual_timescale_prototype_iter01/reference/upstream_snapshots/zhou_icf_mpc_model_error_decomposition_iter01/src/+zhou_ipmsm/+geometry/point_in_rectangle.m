function [inside, residual] = point_in_rectangle(point_ab, rect, tolerance)
%POINT_IN_RECTANGLE Test both independent constraints from paper equation (8).

arguments
    point_ab (1,2) double {mustBeFinite}
    rect struct
    tolerance (1,1) double {mustBeNonnegative} = rect.tolerance
end

point_dq = zhou_ipmsm.math.park(point_ab(:), rect.theta);
delta = abs(point_dq - rect.center_dq) - rect.half_dq;
inside = all(delta <= tolerance);
residual = max(delta);
end

