function tests = test_no_illegal_command_matrix
tests = functiontests(localfunctions);
end

function testSixOperatingConditionsRemainCommandLegal(testCase)
[project,~]=validation_test_fixture("P1");
matrix=experiment_matrix(project.base);
for k=1:numel(matrix)
    scenario=matrix(k);
    scenario.reference_profile="constant";
    scenario.simulation_time_s=1e-3;
    scenario.steady_window_start_s=0;
    scenario.id0_A=scenario.id_ref_A;
    scenario.iq0_A=scenario.iq_ref_A;
    scenario.controller_alpha_d=1/project.paper.Ld_H;
    scenario.controller_alpha_q=1/project.paper.Lq_H;
    sim=zhou_ipmsm.sim.run_closed_loop("ICF_MPC",scenario,project);
    verifyTrue(testCase,all(sim.log.command_legal), ...
        sprintf('%s generated an illegal selected command.',scenario.name));
    verifyFalse(testCase,any(sim.log.illegal_selected | sim.log.illegal_applied));
    verifyTrue(testCase,all(ismember(sim.log.case_selected,[1 2 3])));
    verifyEqual(testCase,sum(sim.log.tiny_negative_dwell_count),0);
    for row=1:height(sim.log)
        d=sscanf(char(sim.log.sequence_durations_s(row)),'%f;');
        verifyGreaterThanOrEqual(testCase,min(d),0);
        verifyEqual(testCase,sum(d),project.paper.Ts_s,'AbsTol',1e-12);
    end
end
end
