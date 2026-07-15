function rect = build_rectangle(Vd, Vq, Jd_limit, Jq_limit, ...
        alpha_d, alpha_q, Ts, theta, tolerance)
%BUILD_RECTANGLE Construct the independent-constraint rectangle.
% Main construction uses paper equations (8) and (6). Equation (9)/(11)
% is evaluated in parallel whenever nonsingular for an audit cross-check.

arguments
    Vd (1,1) double {mustBeFinite}
    Vq (1,1) double {mustBeFinite}
    Jd_limit (1,1) double {mustBeNonnegative, mustBeFinite}
    Jq_limit (1,1) double {mustBeNonnegative, mustBeFinite}
    alpha_d (1,1) double {mustBePositive, mustBeFinite}
    alpha_q (1,1) double {mustBePositive, mustBeFinite}
    Ts (1,1) double {mustBePositive, mustBeFinite}
    theta (1,1) double {mustBeFinite}
    tolerance (1,1) double {mustBeNonnegative} = 1e-10
end

sqrt_Jd = sqrt(Jd_limit);
sqrt_Jq = sqrt(Jq_limit);
center_dq = [Vd / (Ts * alpha_d); Vq / (Ts * alpha_q)];
half_dq = [sqrt_Jd / (Ts * alpha_d); sqrt_Jq / (Ts * alpha_q)];

ud_lo = center_dq(1) - half_dq(1);
ud_hi = center_dq(1) + half_dq(1);
uq_lo = center_dq(2) - half_dq(2);
uq_hi = center_dq(2) + half_dq(2);

% Paper equation (11) labels: a=(d1,q1), b=(d1,q2),
% c=(d2,q1), d=(d2,q2).
corners_dq = [ud_lo, uq_lo; ... % a
              ud_lo, uq_hi; ... % b
              ud_hi, uq_lo; ... % c
              ud_hi, uq_hi];    % d
R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
corners_ab = (R * corners_dq.').';
center_ab = R * center_dq;
polygon_order = [1, 2, 4, 3, 1];

rect = struct();
rect.Vd = Vd;
rect.Vq = Vq;
rect.Jd_limit = Jd_limit;
rect.Jq_limit = Jq_limit;
rect.sqrt_Jd = sqrt_Jd;
rect.sqrt_Jq = sqrt_Jq;
rect.alpha_d = alpha_d;
rect.alpha_q = alpha_q;
rect.Ts = Ts;
rect.theta = theta;
rect.center_dq = center_dq;
rect.center_ab = center_ab;
rect.half_dq = half_dq;
rect.corners_dq = corners_dq;
rect.corners_ab = corners_ab;
rect.polygon_ab = corners_ab(polygon_order, :);
rect.area_V2 = 4 * half_dq(1) * half_dq(2);
rect.tolerance = tolerance;

% Literal equation (9) quantities under the dimensionally consistent
% whole-numerator interpretation documented in ambiguities A16.
s = sin(theta);
c = cos(theta);
analytic_valid = abs(s) > tolerance && abs(c) > tolerance;
analytic = struct('valid', false, 'm', NaN, 'n', NaN, ...
    'p1', NaN, 'p2', NaN, 'q1', NaN, 'q2', NaN, ...
    'corners_ab', NaN(4, 2), 'max_corner_error_V', NaN);
if analytic_valid
    analytic.m = -c / s;
    analytic.n = s / c;
    analytic.p1 = (Vd - sqrt_Jd) / (Ts * alpha_d * s);
    analytic.p2 = (Vd + sqrt_Jd) / (Ts * alpha_d * s);
    analytic.q1 = (Vq - sqrt_Jq) / (Ts * alpha_q * c);
    analytic.q2 = (Vq + sqrt_Jq) / (Ts * alpha_q * c);
    den = analytic.m - analytic.n;
    if abs(den) > tolerance
        p = [analytic.p1, analytic.p1, analytic.p2, analytic.p2];
        q = [analytic.q1, analytic.q2, analytic.q1, analytic.q2];
        x = (q - p) / den;
        y = (analytic.m * q - p * analytic.n) / den;
        analytic.corners_ab = [x(:), y(:)];
        analytic.max_corner_error_V = max(vecnorm( ...
            analytic.corners_ab - corners_ab, 2, 2));
        analytic.valid = true;
    end
end
rect.eq9_analytic = analytic;
end

