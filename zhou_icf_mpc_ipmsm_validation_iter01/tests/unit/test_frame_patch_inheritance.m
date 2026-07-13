function tests = test_frame_patch_inheritance
tests = functiontests(localfunctions);
end

function testSegmentMidpointAnglesAndOnePeriodDelay(testCase)
p=ipmsm_parameters(); a=implementation_assumptions(); Ts=p.Ts_s;
vectors=zhou_ipmsm.inverter.voltage_vectors(48,2/3);
reference=.3*vectors.ab_V(2,:)+.2*vectors.ab_V(3,:);
command=zhou_ipmsm.modulation.case3_command(reference,Ts,vectors,1e-12,1e-12);
theta=.37; omega=123.4;
[pending,pending_angles]=zhou_ipmsm.controller.sequence_equivalent_dq_voltage( ...
    command,vectors,theta,omega,0,Ts,"execution_segment_midpoint");
[selected,selected_angles]=zhou_ipmsm.controller.sequence_equivalent_dq_voltage( ...
    command,vectors,theta,omega,1,Ts,"execution_segment_midpoint");
d=command.sequence_durations_s(:); starts=[0;cumsum(d(1:end-1))];
verifyEqual(testCase,pending_angles,mod(theta+omega*(starts+d/2),2*pi),'AbsTol',1e-14);
verifyEqual(testCase,selected_angles,mod(theta+omega*(Ts+starts+d/2),2*pi),'AbsTol',1e-14);
verifyGreaterThan(testCase,norm(selected-pending),1e-8);

ref_pending=zhou_iter11_ref.controller.sequence_equivalent_dq_voltage( ...
    command,vectors,theta,omega,0,Ts,a.candidate_voltage_frame_mode);
ref_selected=zhou_iter11_ref.controller.sequence_equivalent_dq_voltage( ...
    command,vectors,theta,omega,1,Ts,a.candidate_voltage_frame_mode);
verifyEqual(testCase,pending,ref_pending,'AbsTol',1e-12);
verifyEqual(testCase,selected,ref_selected,'AbsTol',1e-12);
verifyEqual(testCase,mod(theta+1.5*omega*Ts,2*pi), ...
    mod(theta+omega*(Ts+Ts/2),2*pi),'AbsTol',1e-15);
end
