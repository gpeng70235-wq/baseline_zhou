function tests = test_no_negative_duration_ipmsm
tests = functiontests(localfunctions);
end

function testAllCasesAndSixSectors(test_case)
Ts = 1e-4;
vectors = zhou_ipmsm.inverter.voltage_vectors(48);
case1 = zhou_ipmsm.modulation.generate_case_sequence([0 0],Ts,vectors);
verify_sequence(test_case,case1,Ts,1);

for active_id = 1:6
    reference = 0.4*vectors.ab_V(active_id+1,:);
    case2 = zhou_ipmsm.modulation.generate_case_sequence( ...
        reference,Ts,vectors,1e-10,2,active_id);
    verify_sequence(test_case,case2,Ts,2);
end

lower = [1 3 3 5 5 1];
upper = [2 2 4 4 6 6];
for sector = 1:6
    reference = 0.3*vectors.ab_V(lower(sector)+1,:) + ...
        0.2*vectors.ab_V(upper(sector)+1,:);
    case3 = zhou_ipmsm.modulation.generate_case_sequence(reference,Ts,vectors);
    verify_sequence(test_case,case3,Ts,3);
    verifyEqual(test_case,case3.sequence_vector_ids, ...
        [0 lower(sector) upper(sector) lower(sector) 0]);
end
end

function verify_sequence(test_case,command,Ts,expected_case)
verifyEqual(test_case,command.case_id,expected_case);
verifyGreaterThanOrEqual(test_case,min(command.sequence_durations_s),0);
verifyEqual(test_case,sum(command.sequence_durations_s),Ts,'AbsTol',100*eps(Ts));
verifyTrue(test_case,command.sequence_legal);
verifyTrue(test_case,command.requested_feasible);
verifyTrue(test_case,command.legal);
end
