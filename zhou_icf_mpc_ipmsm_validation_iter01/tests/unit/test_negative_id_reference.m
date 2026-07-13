function tests = test_negative_id_reference
tests = functiontests(localfunctions);
end

function testNegativeIdTraversesClosedLoopAndProducesReluctanceTorque(testCase)
[project,scenario]=validation_test_fixture("P1");
scenario.id0_A=-2; scenario.id_ref_A=-2;
scenario.iq0_A=6; scenario.iq_ref_A=6;
scenario.simulation_time_s=4e-3;
sim=zhou_ipmsm.sim.run_closed_loop("ICF_MPC",scenario,project);
verifyEqual(testCase,sim.log.id_ref_A,-2*ones(height(sim.log),1),'AbsTol',0);
verifyLessThan(testCase,mean(sim.log.id_A(end-9:end)),-1);
components=zhou_ipmsm.model.torque_components( ...
    [sim.log.id_A(end-9:end),sim.log.iq_A(end-9:end)],sim.plant_motor);
verifyGreaterThan(testCase,mean(components.reluctance_Nm),0);
verifyTrue(testCase,all(sim.log.command_legal));
end
