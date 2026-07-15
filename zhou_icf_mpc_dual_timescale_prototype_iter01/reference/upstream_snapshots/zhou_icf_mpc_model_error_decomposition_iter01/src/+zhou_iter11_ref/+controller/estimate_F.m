function Fhat = estimate_F(current_dq, previous_current_dq, ...
        applied_voltage_dq, alpha_dq, Ts, history_valid, initial_F)
%ESTIMATE_F Causal Euler-equivalent online estimate for paper equation (2).
% The paper omits an executable estimator; this is assumption A01.

arguments
    current_dq (2,1) double {mustBeFinite}
    previous_current_dq (2,1) double {mustBeFinite}
    applied_voltage_dq (2,1) double {mustBeFinite}
    alpha_dq (2,1) double {mustBePositive, mustBeFinite}
    Ts (1,1) double {mustBePositive, mustBeFinite}
    history_valid (1,1) logical
    initial_F (2,1) double {mustBeFinite} = [0;0]
end

if history_valid
    Fhat = (current_dq - previous_current_dq) / Ts - ...
        alpha_dq .* applied_voltage_dq;
else
    Fhat = initial_F;
end
end

