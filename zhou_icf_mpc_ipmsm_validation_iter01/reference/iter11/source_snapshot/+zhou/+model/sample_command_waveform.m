function [sample_states, audit] = sample_command_waveform( ...
        initial_state, command, vectors, omega_e, motor, Ts, sample_period, tolerance, delta_voltage_ab)
%SAMPLE_COMMAND_WAVEFORM Replay the applied switch sequence on a uniform grid.
% This observer is read-only: its endpoint is audited against, but never fed
% back to, the control-cycle plant state.

arguments
    initial_state (3,1) double {mustBeFinite}
    command struct
    vectors struct
    omega_e (1,1) double {mustBeFinite}
    motor struct
    Ts (1,1) double {mustBePositive}
    sample_period (1,1) double {mustBePositive}
    tolerance (1,1) double {mustBeNonnegative} = 1e-13
    delta_voltage_ab (1,2) double {mustBeFinite} = [0,0]
end

sample_count = round(Ts/sample_period);
assert(abs(sample_count*sample_period-Ts) <= max(tolerance,100*eps(Ts)), ...
    'Zhou:WaveformGridMismatch', ...
    'The waveform sample period must divide the control period exactly.');

durations = command.sequence_durations_s(:).';
ids = command.sequence_vector_ids(:).';
assert(numel(durations)==numel(ids) && all(isfinite(durations)), ...
    'Zhou:InvalidSequence','Invalid switching sequence for waveform replay.');
assert(all(durations >= -tolerance), 'Zhou:NegativeDwell', ...
    'Waveform replay received a negative dwell time.');
durations(durations < 0) = 0;
assert(abs(sum(durations)-Ts) <= max(tolerance,100*eps(Ts)), ...
    'Zhou:DwellSumFailure','Waveform replay dwell times do not sum to Ts.');

sample_states = zeros(3,sample_count+1);
sample_states(:,1) = initial_state;
state = initial_state;
cursor = 0;
segment = 1;
segment_end = durations(1);

for sample = 2:sample_count+1
    target = (sample-1)*sample_period;
    while cursor < target-tolerance
        while segment < numel(ids) && segment_end <= cursor+tolerance
            segment = segment+1;
            segment_end = segment_end+durations(segment);
        end
        stop = min(target,segment_end);
        dt = stop-cursor;
        if dt > tolerance
            voltage_ab = vectors.ab_V(ids(segment)+1,:);
            state = rk4_step(state,voltage_ab,omega_e,motor,dt,delta_voltage_ab);
            cursor = stop;
        else
            cursor = stop;
        end
    end
    sample_states(:,sample) = state;
end

audit = struct();
audit.sample_period_s = sample_period;
audit.samples_per_control_period = sample_count;
audit.endpoint_state = sample_states(:,end);
audit.integrated_time_s = cursor;
audit.time_residual_s = abs(cursor-Ts);
end

function next = rk4_step(state,voltage_ab,omega_e,motor,dt,delta_voltage_ab)
k1 = zhou.model.pmsm_derivative(state,voltage_ab,omega_e,motor,delta_voltage_ab);
k2 = zhou.model.pmsm_derivative(state+dt*k1/2,voltage_ab,omega_e,motor,delta_voltage_ab);
k3 = zhou.model.pmsm_derivative(state+dt*k2/2,voltage_ab,omega_e,motor,delta_voltage_ab);
k4 = zhou.model.pmsm_derivative(state+dt*k3,voltage_ab,omega_e,motor,delta_voltage_ab);
next = state+dt*(k1+2*k2+2*k3+k4)/6;
end
