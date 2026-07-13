function [Fhat,audit] = algebraic_F_iter11(current_history,voltage_history,alpha_dq,Ts)
%ALGEBRAIC_F_ITER11 Frozen Iteration 11 Fliess-Join algebraic estimator.
% current_history contains N+1 current boundaries. voltage_history contains
% the N causal, actually-applied ideal dq interval voltages between them.

arguments
    current_history (2,:) double {mustBeFinite}
    voltage_history (2,:) double {mustBeFinite}
    alpha_dq (2,1) double {mustBePositive,mustBeFinite}
    Ts (1,1) double {mustBePositive,mustBeFinite}
end

N = size(voltage_history,2);
assert(N >= 1 && size(current_history,2) == N+1, ...
    'ZhouIPMSM:EstimatorHistory', ...
    'Expected N+1 current boundaries and N applied-voltage intervals.');

L = N*Ts;
integral_value = zeros(2,1);
for j = 1:N
    left = (j-1)*Ts;
    right = j*Ts;
    slope = (current_history(:,j+1)-current_history(:,j))/Ts;
    intercept = current_history(:,j)-slope*left;
    int_y = intercept.*(L*(right-left)-(right^2-left^2)) + ...
        slope.*(L/2*(right^2-left^2)-2/3*(right^3-left^3));
    int_u = L/2*(right^2-left^2)-1/3*(right^3-left^3);
    integral_value = integral_value + int_y + ...
        alpha_dq.*voltage_history(:,j)*int_u;
end
Fhat = -6/L^3*integral_value;

audit = struct();
audit.estimator = "algebraic_iter11";
audit.window_samples = N;
audit.window_duration_s = L;
audit.current_boundaries = N+1;
audit.applied_intervals = N;
audit.causal = true;
audit.online = true;
audit.uses_future_measurement = false;
audit.quadrature = ...
    "exact_piecewise_linear_current_zero_order_hold_applied_voltage";
end
