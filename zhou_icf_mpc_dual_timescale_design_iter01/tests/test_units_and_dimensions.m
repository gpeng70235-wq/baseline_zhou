function tests = test_units_and_dimensions
tests = functiontests(localfunctions);
end

function test_shapes_and_two_Ts_steps(testCase)
cfg=design.project_parameter();
p=design.reference_predictor([1;2],[3;4],[5;6],[7;8],[7;8], ...
    cfg.alpha_initial_A_per_Vs,false,cfg);
verifySize(testCase,p.i_hat_k1_given_k_A,[2 1]);
verifySize(testCase,p.i_hat_k2_given_k_A,[2 1]);
expected=[1;2]+cfg.Ts_s*([7;8]+cfg.alpha_initial_A_per_Vs.*[3;4])+ ...
    cfg.Ts_s*([7;8]+cfg.alpha_initial_A_per_Vs.*[5;6]);
verifyEqual(testCase,p.i_hat_k2_given_k_A,expected,'AbsTol',1e-12);
end
