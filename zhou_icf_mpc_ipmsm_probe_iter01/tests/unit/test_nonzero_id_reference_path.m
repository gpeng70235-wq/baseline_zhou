function tests = test_nonzero_id_reference_path
tests = functiontests(localfunctions);
end

function testNegativeIdClosedLoop(test_case)
verifyEqual(test_case,zhou_ipmsm.controller.build_current_reference(-4,10),[-4;10]);
cfg = make_cfg();
cfg.id_ref = -4;
cfg.steps = 160;
cfg.reference_ramp_s = 2e-3;
[metrics,trace] = zhou_ipmsm.run_probe_case(cfg);
verifyLessThan(test_case,mean(trace.current(1,end-30:end)),-2);
verifyGreaterThan(test_case,mean(trace.current(2,end-30:end)),7);
verifyGreaterThan(test_case,metrics.mean_reluctance_torque_Nm,0);
verifyEqual(test_case,metrics.illegal_commands,0);
verifyEqual(test_case,metrics.negative_durations,0);
end

function cfg = make_cfg()
cfg = base_parameters();
cfg.motor = ipmsm_parameters();
cfg.experiments = experiment_definitions();
cfg.acceptance = acceptance_thresholds();
cfg.assumptions = implementation_assumptions();
end
