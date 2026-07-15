function tests = test_dq_axis_independence
tests = functiontests(localfunctions);
end

function test_d_update_does_not_overwrite_q(testCase)
cfg=design.project_parameter();a0=cfg.alpha_initial_A_per_Vs;
gate=struct('g_alpha_dq',[true;false],'alpha_step_scale',1);
[a1,~]=design.reference_alpha_update(a0,[4;99], ...
    [a0(1)*4+100;-1e9],gate,cfg);
verifyNotEqual(testCase,a1(1),a0(1));
verifyEqual(testCase,a1(2),a0(2),'AbsTol',0);
verifyNotEqual(testCase,cfg.alpha_initial_A_per_Vs(1), ...
    cfg.alpha_initial_A_per_Vs(2));
end
