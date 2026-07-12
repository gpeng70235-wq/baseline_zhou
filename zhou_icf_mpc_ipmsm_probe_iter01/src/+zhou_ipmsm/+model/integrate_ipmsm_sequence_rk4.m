function state = integrate_ipmsm_sequence_rk4(state, command, vectors, ...
        theta_start, omega_e, motor, expected_Ts)
%INTEGRATE_IPMSM_SEQUENCE_RK4 Piecewise switching-state IPMSM integration.
durations = command.sequence_durations_s(:);
ids = command.sequence_vector_ids(:);
if nargin < 7
    expected_Ts = sum(durations);
end
tolerance = max(100*eps(expected_Ts),1e-15);
assert(numel(durations)==numel(ids) && all(isfinite(durations)) && ...
    all(isfinite(ids)) && all(ids==round(ids)) && all(ids>=0 & ids<=6), ...
    'ZhouIPMSM:InvalidSequence','Sequence durations and vector ids are invalid.');
assert(all(durations>=-tolerance) && ...
    abs(sum(durations)-expected_Ts)<=tolerance, ...
    'ZhouIPMSM:InvalidSequenceTiming','Sequence duration contract is violated.');
durations(durations<0) = 0;

elapsed = 0;
for segment = 1:numel(durations)
    h = durations(segment);
    if h<=0
        continue;
    end
    voltage_ab = vectors.ab_V(ids(segment)+1,:);
    derivative = @(x,tau) zhou_ipmsm.model.ipmsm_dq_dynamics(x, ...
        zhou_ipmsm.inverter.park(voltage_ab,theta_start+omega_e*(elapsed+tau)), ...
        omega_e,motor);
    k1 = derivative(state,0);
    k2 = derivative(state+h*k1/2,h/2);
    k3 = derivative(state+h*k2/2,h/2);
    k4 = derivative(state+h*k3,h);
    state = state+h*(k1+2*k2+2*k3+k4)/6;
    elapsed = elapsed+h;
end
assert(all(isfinite(state)),'ZhouIPMSM:NonfinitePlantState', ...
    'IPMSM integration produced a nonfinite state.');
end
