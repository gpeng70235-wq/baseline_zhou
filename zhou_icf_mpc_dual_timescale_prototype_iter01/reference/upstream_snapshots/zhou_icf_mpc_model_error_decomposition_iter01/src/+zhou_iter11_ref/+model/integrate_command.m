function [next_state, applied_average_dq, integration_audit] = ...
        integrate_command(state, command, vectors, omega_e, motor, Ts, tolerance, delta_voltage_ab)
%INTEGRATE_COMMAND Piecewise RK4 integration of the commanded switch sequence.

arguments
    state (3,1) double {mustBeFinite}
    command struct
    vectors struct
    omega_e (1,1) double {mustBeFinite}
    motor struct
    Ts (1,1) double {mustBePositive}
    tolerance (1,1) double {mustBeNonnegative} = 1e-13
    delta_voltage_ab (1,2) double {mustBeFinite} = [0,0]
end

durations = command.sequence_durations_s(:).';
ids = command.sequence_vector_ids(:).';
assert(numel(durations) == numel(ids), 'ZhouIter11Ref:InvalidSequence', ...
    'Sequence vector IDs and durations must have equal lengths.');
assert(all(isfinite(durations)) && all(durations >= -tolerance), ...
    'ZhouIter11Ref:NegativeDwell', 'Illegal negative/nonfinite dwell time: %s.', ...
    mat2str(durations,17));
assert(abs(sum(durations) - Ts) <= max(tolerance, 100*eps(Ts)), ...
    'ZhouIter11Ref:DwellSumFailure', 'Sequence dwell times do not sum to Ts.');

next_state = state;
applied_average_dq = [0;0];
elapsed = 0;
tiny_negative_count = 0;
for segment = 1:numel(ids)
    dt = durations(segment);
    if dt < 0
        tiny_negative_count = tiny_negative_count + 1;
        dt = 0;
    end
    if dt == 0
        continue;
    end
    voltage_ab = vectors.ab_V(ids(segment) + 1, :);
    theta_mid = state(3) + omega_e*(elapsed + dt/2);
    applied_average_dq = applied_average_dq + ...
        dt/Ts * zhou_iter11_ref.math.park(voltage_ab, theta_mid);

    k1 = zhou_iter11_ref.model.pmsm_derivative(next_state,voltage_ab,omega_e,motor,delta_voltage_ab);
    k2 = zhou_iter11_ref.model.pmsm_derivative(next_state+dt*k1/2,voltage_ab,omega_e,motor,delta_voltage_ab);
    k3 = zhou_iter11_ref.model.pmsm_derivative(next_state+dt*k2/2,voltage_ab,omega_e,motor,delta_voltage_ab);
    k4 = zhou_iter11_ref.model.pmsm_derivative(next_state+dt*k3,voltage_ab,omega_e,motor,delta_voltage_ab);
    next_state = next_state + dt*(k1 + 2*k2 + 2*k3 + k4)/6;
    elapsed = elapsed + dt;
end

integration_audit = struct();
integration_audit.tiny_negative_count = tiny_negative_count;
integration_audit.integrated_time_s = elapsed;
integration_audit.time_residual_s = abs(elapsed - Ts);
end
