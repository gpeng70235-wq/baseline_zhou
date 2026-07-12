function tests = test_ipmsm_torque_equation
tests = functiontests(localfunctions);
end

function testClosedFormComponents(test_case)
p = ipmsm_parameters();
current = [-4;10];
scale = 1.5*p.pole_pairs;
expected_magnet = scale*p.psi_f*current(2);
expected_reluctance = scale*(p.Ld-p.Lq)*current(1)*current(2);
expected_total = expected_magnet+expected_reluctance;
components = zhou_ipmsm.model.calculate_torque_components(current,p);
verifyEqual(test_case,components.magnet,expected_magnet,'RelTol',1e-14);
verifyEqual(test_case,components.reluctance,expected_reluctance,'RelTol',1e-14);
verifyEqual(test_case,zhou_ipmsm.model.calculate_ipmsm_torque(current,p), ...
    expected_total,'RelTol',1e-14);
verifyGreaterThan(test_case,components.reluctance,0);
end
