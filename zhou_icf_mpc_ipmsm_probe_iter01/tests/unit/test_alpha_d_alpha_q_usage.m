function tests = test_alpha_d_alpha_q_usage
tests = functiontests(localfunctions);
end

function testControllerUsesBothAxes(test_case)
cfg = make_cfg();
vectors = zhou_ipmsm.inverter.voltage_vectors(cfg.Vdc);
pending = zhou_ipmsm.modulation.generate_case_sequence([0 0],cfg.Ts,vectors);
output = zhou_ipmsm.controller.icf_mpc_step([0;0],[0;0],[0;0],pending, ...
    [0;0],0,100,cfg,false);
verifyEqual(test_case,output.alpha_dq,[1/cfg.motor.Ld;1/cfg.motor.Lq], ...
    'RelTol',1e-14);
verifyNotEqual(test_case,output.alpha_dq(1),output.alpha_dq(2));
cfg.alpha_mode = 'common_Ls';
common = zhou_ipmsm.controller.icf_mpc_step([0;0],[0;0],[0;0],pending, ...
    [0;0],0,100,cfg,false);
verifyEqual(test_case,common.alpha_dq(1),common.alpha_dq(2));
end

function cfg = make_cfg()
cfg = base_parameters();
cfg.motor = ipmsm_parameters();
cfg.experiments = experiment_definitions();
cfg.acceptance = acceptance_thresholds();
cfg.assumptions = implementation_assumptions();
end
