function tests = test_ipmsm_reduces_to_smpmsm
tests = functiontests(localfunctions);
end

function testReduction(test_case)
p = ipmsm_parameters();
p.Ld = 1e-3;
p.Lq = p.Ld;
current = [-2;8];
voltage = [5;10];
omega = 200;
actual = zhou_ipmsm.model.ipmsm_dq_dynamics(current,voltage,omega,p);
expected = [(voltage(1)-p.Rs*current(1)+omega*p.Ld*current(2))/p.Ld; ...
    (voltage(2)-p.Rs*current(2)-omega*(p.Ld*current(1)+p.psi_f))/p.Ld];
verifyEqual(test_case,actual,expected,'RelTol',1e-14);
components = zhou_ipmsm.model.calculate_torque_components(current,p);
verifyEqual(test_case,components.reluctance,0,'AbsTol',1e-15);
end
