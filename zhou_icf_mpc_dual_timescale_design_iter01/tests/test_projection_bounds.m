function tests = test_projection_bounds
tests = functiontests(localfunctions);
end

function test_projection_is_hard(testCase)
cfg=design.project_parameter();
gate=struct('g_alpha_dq',[true;true],'alpha_step_scale',1);
[high,~]=design.reference_alpha_update(cfg.alpha_initial_A_per_Vs, ...
    [10;10],[1e9;1e9],gate,cfg);
[low,~]=design.reference_alpha_update(cfg.alpha_initial_A_per_Vs, ...
    [10;10],[-1e9;-1e9],gate,cfg);
verifyLessThanOrEqual(testCase,high,cfg.alpha_max_A_per_Vs);
verifyGreaterThanOrEqual(testCase,low,cfg.alpha_min_A_per_Vs);
end
