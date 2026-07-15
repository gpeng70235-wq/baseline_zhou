function tests = test_state_reset
tests = functiontests(localfunctions);
end

function test_reset_is_deterministic_and_invalidates_history(testCase)
a=design.project_parameter('reset');b=design.project_parameter('reset');
verifyEqual(testCase,a,b);verifyFalse(testCase,a.history_valid);
verifyEqual(testCase,a.alpha_hat_A_per_Vs, ...
    design.project_parameter().alpha_initial_A_per_Vs);
verifyFalse(testCase,a.decision_gate_latched);
end
