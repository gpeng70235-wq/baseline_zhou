function tests = test_ipmsm_torque_components
tests = functiontests(localfunctions);
end

function testMagnetReluctanceAndTotalTorque(testCase)
p=ipmsm_parameters(); current=[-4;10]; scale=1.5*p.pole_pairs;
expected_magnet=scale*p.psi_f_Wb*current(2);
expected_reluctance=scale*(p.Ld_H-p.Lq_H)*current(1)*current(2);
c=zhou_ipmsm.model.torque_components(current,p);
verifyEqual(testCase,c.magnet_Nm,expected_magnet,'RelTol',1e-14);
verifyEqual(testCase,c.reluctance_Nm,expected_reluctance,'RelTol',1e-14);
verifyGreaterThan(testCase,c.reluctance_Nm,0);
verifyEqual(testCase,c.total_Nm,expected_magnet+expected_reluctance,'RelTol',1e-14);
verifyEqual(testCase,zhou_ipmsm.model.electromagnetic_torque(current,p), ...
    c.total_Nm,'RelTol',1e-14);
end

function testReluctanceTorqueVanishesAtP0(testCase)
p=ipmsm_parameters(); p.Ld_H=p.Ls_H; p.Lq_H=p.Ls_H;
c=zhou_ipmsm.model.torque_components([-6;12],p);
verifyEqual(testCase,c.reluctance_Nm,0,'AbsTol',1e-15);
verifyEqual(testCase,c.total_Nm,c.magnet_Nm,'AbsTol',1e-15);
end
