function [Jd, Jq] = costs_from_voltage(V, candidate_ab, theta, alpha_dq, Ts)
%COSTS_FROM_VOLTAGE Paper equation (7).

candidate_dq = zhou_ipmsm.math.park(candidate_ab, theta);
error_dq = V(:) - Ts * alpha_dq(:) .* candidate_dq(:);
Jd = error_dq(1)^2;
Jq = error_dq(2)^2;
end

