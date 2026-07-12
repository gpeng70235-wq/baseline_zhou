function tests = test_ipmsm_dq_equation_signs
tests = functiontests(localfunctions);
end

function testExplicitEquationOracle(test_case)
p = ipmsm_parameters();
current = [-3;7];
voltage = [5;11];
omega = 140;
expected = [(voltage(1)-p.Rs*current(1)+omega*p.Lq*current(2))/p.Ld; ...
    (voltage(2)-p.Rs*current(2)-omega*(p.Ld*current(1)+p.psi_f))/p.Lq];
actual = zhou_ipmsm.model.ipmsm_dq_dynamics(current,voltage,omega,p);
verifyEqual(test_case,actual,expected,'RelTol',1e-14);

cross_d = zhou_ipmsm.model.ipmsm_dq_dynamics([0;1],[0;0],100,p);
verifyGreaterThan(test_case,cross_d(1),0);
verifyLessThan(test_case,cross_d(2),0);
end
