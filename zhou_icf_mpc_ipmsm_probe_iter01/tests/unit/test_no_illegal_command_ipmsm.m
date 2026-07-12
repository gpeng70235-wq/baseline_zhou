function tests = test_no_illegal_command_ipmsm
tests = functiontests(localfunctions);
end

function testGeometryAndClosedLoopContracts(test_case)
Ts = 1e-4;
alpha = [1000;800];
case1 = classify_for_center([0;0],[1;1],alpha,Ts);
case2 = classify_for_center([5;1],[1;1],alpha,Ts);
case3 = classify_for_center([5;2],[0.5;0.5],alpha,Ts);
verifyEqual(test_case,[case1.case_id case2.case_id case3.case_id],[1 2 3]);

vectors = zhou_ipmsm.inverter.voltage_vectors(48);
zero_command = zhou_ipmsm.modulation.generate_case_sequence([0 0],Ts,vectors);
verifyTrue(test_case,zhou_ipmsm.geometry.validate_candidate_geometry(zero_command,Ts));
infeasible = zhou_ipmsm.modulation.generate_case_sequence( ...
    2*vectors.ab_V(2,:),Ts,vectors,1e-10,3);
verifyFalse(test_case,infeasible.requested_feasible);
verifyTrue(test_case,infeasible.sequence_legal);
verifyFalse(test_case,infeasible.legal);
verifyTrue(test_case,infeasible.saturation_used);

cfg = make_cfg();
cfg.steps = 100;
cfg.reference_ramp_s = 3e-3;
metrics = zhou_ipmsm.run_probe_case(cfg);
verifyEqual(test_case,metrics.illegal_commands,0);
verifyEqual(test_case,metrics.negative_durations,0);
verifyEqual(test_case,metrics.constraint_d_violations,0);
verifyEqual(test_case,metrics.constraint_q_violations,0);
verifyEqual(test_case,metrics.geometry_reference_outside,0);
verifyEqual(test_case,metrics.saturated_commands,0);
end

function classification = classify_for_center(center,half_width,alpha,Ts)
V = center.*(Ts*alpha);
J = (half_width.*Ts.*alpha).^2;
rect = zhou_ipmsm.geometry.build_voltage_rectangle(V,J,alpha,Ts,0);
classification = zhou_ipmsm.geometry.classify_case(rect);
end

function cfg = make_cfg()
cfg = base_parameters();
cfg.motor = ipmsm_parameters();
cfg.experiments = experiment_definitions();
cfg.acceptance = acceptance_thresholds();
cfg.assumptions = implementation_assumptions();
end
