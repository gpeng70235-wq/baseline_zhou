function tests = test_ipmsm_equation_signs
tests = functiontests(localfunctions);
end

function testExplicitDqEquationOracle(testCase)
p = ipmsm_parameters();
state = [-3;7;0]; voltage_dq = [5;11]; omega = 140;
expected = [(voltage_dq(1)-p.Rs_Ohm*state(1)+omega*p.Lq_H*state(2))/p.Ld_H; ...
    (voltage_dq(2)-p.Rs_Ohm*state(2)-omega*(p.Ld_H*state(1)+p.psi_f_Wb))/p.Lq_H; ...
    omega];
actual = zhou_ipmsm.model.pmsm_derivative(state,voltage_dq,omega,p);
verifyEqual(testCase,actual,expected,'RelTol',1e-13);

cross = zhou_ipmsm.model.pmsm_derivative([0;1;0],[0,0],100,p);
verifyGreaterThan(testCase,cross(1),0);
verifyLessThan(testCase,cross(2),0);
end

function testDegenerateEquationMatchesReference(testCase)
p = ipmsm_parameters(); p.Ld_H=p.Ls_H; p.Lq_H=p.Ls_H;
x=[-2;8;0.31]; u=[4,-7]; omega=200;
a=zhou_ipmsm.model.pmsm_derivative(x,u,omega,p);
b=zhou_iter11_ref.model.pmsm_derivative(x,u,omega,p);
verifyEqual(testCase,a,b,'AbsTol',1e-12);
end
