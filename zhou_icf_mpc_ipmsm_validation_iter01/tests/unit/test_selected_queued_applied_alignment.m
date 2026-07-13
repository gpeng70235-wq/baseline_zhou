function tests = test_selected_queued_applied_alignment
tests = functiontests(localfunctions);
end

function testOneCycleQueueAlignment(testCase)
[project,scenario]=validation_test_fixture("P1");
scenario.simulation_time_s=5e-3;
sim=zhou_ipmsm.sim.run_closed_loop("ICF_MPC",scenario,project);
log=sim.log;
verifyEqual(testCase,log.case_applied(2:end),log.case_selected(1:end-1));
verifyTrue(testCase,isequaln(log.applied_vector(2:end),log.selected_vector(1:end-1)));
verifyEqual(testCase,log.switching_actions_applied(2:end), ...
    log.switching_actions_selected(1:end-1));
verifyEqual(testCase,log.applied_sequence_vector_ids(2:end), ...
    log.sequence_vector_ids(1:end-1));
verifyEqual(testCase,log.applied_sequence_states(2:end), ...
    log.sequence_states(1:end-1));
for k=2:height(log)
    applied=sscanf(char(log.applied_sequence_durations_s(k)),'%f;');
    selected=sscanf(char(log.sequence_durations_s(k-1)),'%f;');
    verifyEqual(testCase,applied,selected,'AbsTol',1e-15);
end
verifyTrue(testCase,all(log.command_legal));

% The final selected command is intentionally queued but not applied within
% this finite trace; the N-1 alignment above is therefore the exact contract.
verifyEqual(testCase,height(log)-1,numel(log.case_applied(2:end)));
end
