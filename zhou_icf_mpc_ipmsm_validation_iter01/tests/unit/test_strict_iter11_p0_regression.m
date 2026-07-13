function tests = test_strict_iter11_p0_regression
tests = functiontests(localfunctions);
end

function testIndependentDegenerateClosedLoopsMatchPointwise(testCase)
[project,scenario] = validation_test_fixture("P0");
ref_path = string(which('zhou_iter11_ref.sim.run_closed_loop'));
new_path = string(which('zhou_ipmsm.sim.run_closed_loop'));
verifyNotEqual(testCase,ref_path,new_path, ...
    'P0 must execute two independent namespace implementations.');

reference = zhou_iter11_ref.sim.run_closed_loop("ICF_MPC",scenario,project);
candidate = zhou_ipmsm.sim.run_closed_loop("ICF_MPC",scenario,project);
verifyEqual(testCase,height(candidate.log),height(reference.log));
verifyLessThanOrEqual(testCase,max(abs(candidate.log.id_A-reference.log.id_A)),1e-6);
verifyLessThanOrEqual(testCase,max(abs(candidate.log.iq_A-reference.log.iq_A)),1e-6);
verifyEqual(testCase,candidate.log.case_selected,reference.log.case_selected);
verifyEqual(testCase,candidate.log.case_applied,reference.log.case_applied);
verifyEqual(testCase,candidate.log.sequence_vector_ids,reference.log.sequence_vector_ids);
verifyEqual(testCase,candidate.log.sequence_states,reference.log.sequence_states);
verifyLessThanOrEqual(testCase,max_duration_difference( ...
    candidate.log.sequence_durations_s,reference.log.sequence_durations_s),1e-9);
verifyEqual(testCase,candidate.log.command_legal,true(height(candidate.log),1));

[comparison,summary] = zhou_validation.compare_pointwise_runs( ...
    reference,candidate,scenario,project);
verifyFalse(testCase,isempty(comparison), ...
    'The strict comparison helper returned no pointwise evidence.');
verifyTrue(testCase,all(comparison.case_match));
verifyTrue(testCase,all(comparison.vector_match));
verifyTrue(testCase,all(comparison.duration_structure_match));
verifyTrue(testCase,all(comparison.switching_action_match));
% The algebraic estimator differentiates two independently integrated
% traces, so sub-micro-A/s roundoff is expected even when the current gate
% is satisfied at 1 microampere.
verifyLessThanOrEqual(testCase,max(abs([comparison.Fd_error;comparison.Fq_error])),1e-6);
verifyLessThanOrEqual(testCase,max(abs([comparison.id_pred_k1_error_A; ...
    comparison.iq_pred_k1_error_A;comparison.id_pred_k2_error_A; ...
    comparison.iq_pred_k2_error_A])),1e-6);
verifyLessThanOrEqual(testCase,max(abs([comparison.U3d_error_V; ...
    comparison.U3q_error_V])),1e-6);
verifyEqual(testCase,string(summary.pass_fail),"PASS");
verifyEqual(testCase,summary.case_match_rate,1,'AbsTol',0);
verifyEqual(testCase,summary.vector_match_rate,1,'AbsTol',0);
verifyEqual(testCase,summary.duration_structure_match_rate,1,'AbsTol',0);
verifyEqual(testCase,summary.illegal_commands,0);
verifyEqual(testCase,summary.negative_durations,0);
end

function value = max_duration_difference(left,right)
value = 0;
for k = 1:numel(left)
    a = sscanf(char(left(k)),'%f;').';
    b = sscanf(char(right(k)),'%f;').';
    if numel(a)~=numel(b), value=Inf; return; end
    value = max(value,max(abs(a-b),[],'omitnan'));
end
end
