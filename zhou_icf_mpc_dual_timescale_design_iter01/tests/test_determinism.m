function tests = test_determinism
tests = functiontests(localfunctions);
end

function test_bitwise_repeatability(testCase)
cfg=design.project_parameter();
gate=struct('g_alpha_dq',[true;true],'alpha_step_scale',0.25);
[a1,d1]=design.reference_alpha_update(cfg.alpha_initial_A_per_Vs, ...
    [3;-2],[4000;-1000],gate,cfg);
[a2,d2]=design.reference_alpha_update(cfg.alpha_initial_A_per_Vs, ...
    [3;-2],[4000;-1000],gate,cfg);
verifyEqual(testCase,a1,a2,'AbsTol',0);verifyEqual(testCase,d1,d2);
end
