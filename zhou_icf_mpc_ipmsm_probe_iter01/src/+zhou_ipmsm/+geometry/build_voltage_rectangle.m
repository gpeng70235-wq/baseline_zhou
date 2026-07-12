function rect = build_voltage_rectangle(V_dq, J_limits, alpha_dq, Ts, theta, tolerance)
%BUILD_VOLTAGE_RECTANGLE Independent d/q-current-cost feasible rectangle.
% This is the IPMSM form of Iteration 11 equations (6), (8), and (11):
% alpha_d and alpha_q are kept independent instead of assuming one Ls.

if nargin < 6
    tolerance = 1e-10;
end
V_dq = V_dq(:);
J_limits = J_limits(:);
alpha_dq = alpha_dq(:);
assert(numel(V_dq) == 2 && numel(J_limits) == 2 && numel(alpha_dq) == 2, ...
    'ZhouIPMSM:RectangleInputSize', 'V, J, and alpha must be two-axis values.');
assert(all(isfinite([V_dq; J_limits; alpha_dq])) && all(J_limits >= 0) && ...
    all(alpha_dq > 0) && isfinite(Ts) && Ts > 0, ...
    'ZhouIPMSM:RectangleInputValue', 'Rectangle inputs must be finite and physical.');

center_dq = V_dq ./ (Ts .* alpha_dq);
half_dq = sqrt(J_limits) ./ (Ts .* alpha_dq);
lo = center_dq - half_dq;
hi = center_dq + half_dq;
corners_dq = [lo(1) lo(2); lo(1) hi(2); hi(1) hi(2); hi(1) lo(2)];
rotation = [cos(theta) -sin(theta); sin(theta) cos(theta)];
corners_ab = (rotation * corners_dq')';

rect = struct();
rect.V_dq = V_dq;
rect.J_limits = J_limits;
rect.alpha_dq = alpha_dq;
rect.Ts = Ts;
rect.theta = theta;
rect.center_dq = center_dq;
rect.half_dq = half_dq;
rect.corners_dq = corners_dq;
rect.corners_ab = corners_ab;
rect.polygon_ab = corners_ab([1 2 3 4 1],:);
rect.center_ab = (rotation * center_dq)';
rect.area_V2 = 4 * prod(half_dq);
rect.tolerance = tolerance;
end
