function tests = test_constraint_metric_identity
tests = functiontests(localfunctions);
end

function testEquationFiveAndIndependentEquationSevenOracle(testCase)
Ts=1e-4; alpha=[1250;1/1.2e-3]; theta=.41;
current=[-.3;7.2]; F=[120;-310]; pending=[-4;9]; reference=[-1;8];
predicted_k1=zhou_ipmsm.controller.predict_k1(current,F,pending,alpha,Ts);
V=zhou_ipmsm.controller.compute_V_terms(reference,predicted_k1,F,Ts);
candidate_dq=[5;-6]; candidate_ab=zhou_ipmsm.math.inv_park(candidate_dq,theta).';
predicted_k2=zhou_ipmsm.controller.predict_k2(predicted_k1,F,candidate_dq,alpha,Ts);
[Jd5,Jq5]=zhou_ipmsm.controller.independent_costs(reference,predicted_k2);
[Jd7,Jq7]=zhou_ipmsm.controller.costs_from_voltage(V,candidate_ab,theta,alpha,Ts);
verifyEqual(testCase,[Jd5 Jq5],[Jd7 Jq7],'AbsTol',1e-13);
end

function testLoggedBooleansAreExactlyTheCostDefinition(testCase)
[project,scenario]=validation_test_fixture("P1");
sim=zhou_ipmsm.sim.run_closed_loop("ICF_MPC",scenario,project);
t=project.assumptions.constraint_tolerance_A2;
verifyEqual(testCase,sim.log.constraint_d_ok,sim.log.Jd<=sim.log.Jd_limit+t);
verifyEqual(testCase,sim.log.constraint_q_ok,sim.log.Jq<=sim.log.Jq_limit+t);
end
