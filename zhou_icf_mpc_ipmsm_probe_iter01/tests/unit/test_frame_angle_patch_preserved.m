function tests = test_frame_angle_patch_preserved
tests = functiontests(localfunctions);
end

function testSegmentMidpointOracleAndQueue(test_case)
cfg = make_cfg();
vectors = zhou_ipmsm.inverter.voltage_vectors(cfg.Vdc);
command = zhou_ipmsm.modulation.generate_case_sequence( ...
    0.45*vectors.ab_V(2,:)+0.25*vectors.ab_V(3,:),cfg.Ts,vectors);
theta = 0.37;
omega = 123.4;
delay = 1;
actual = zhou_ipmsm.controller.sequence_equivalent_dq_voltage( ...
    command,vectors,theta,omega,delay,cfg.Ts,'execution_segment_midpoint');
durations = command.sequence_durations_s(:);
starts = [0;cumsum(durations(1:end-1))];
expected = [0;0];
for index = 1:numel(durations)
    angle = theta+omega*(delay*cfg.Ts+starts(index)+durations(index)/2);
    expected = expected+durations(index)/cfg.Ts*zhou_ipmsm.inverter.park( ...
        vectors.ab_V(command.sequence_vector_ids(index)+1,:),angle);
end
verifyEqual(test_case,actual,expected,'AbsTol',1e-12);

legacy = zhou_ipmsm.controller.sequence_equivalent_dq_voltage( ...
    command,vectors,theta,omega,delay,cfg.Ts,'legacy_selection_angle');
verifyGreaterThan(test_case,norm(actual-legacy),1e-6);

control = zhou_ipmsm.controller.icf_mpc_step([0;0],[0;0],[0;0],command, ...
    [0;0],theta,omega,cfg,false);
pending_expected = zhou_ipmsm.controller.sequence_equivalent_dq_voltage( ...
    command,vectors,theta,omega,0,cfg.Ts,cfg.assumptions.frame_mode);
selected_expected = zhou_ipmsm.controller.sequence_equivalent_dq_voltage( ...
    control.command,vectors,theta,omega,1,cfg.Ts,cfg.assumptions.frame_mode);
verifyEqual(test_case,control.pending_voltage_dq_used,pending_expected,'AbsTol',1e-12);
verifyEqual(test_case,control.voltage_dq,selected_expected,'AbsTol',1e-12);
verifyEqual(test_case,control.geometry_theta,mod(theta+1.5*omega*cfg.Ts,2*pi), ...
    'AbsTol',1e-14);
end

function cfg = make_cfg()
cfg = base_parameters();
cfg.motor = ipmsm_parameters();
cfg.experiments = experiment_definitions();
cfg.acceptance = acceptance_thresholds();
cfg.assumptions = implementation_assumptions();
end
