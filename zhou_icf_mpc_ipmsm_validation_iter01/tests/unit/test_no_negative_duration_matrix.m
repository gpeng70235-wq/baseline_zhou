function tests = test_no_negative_duration_matrix
tests = functiontests(localfunctions);
end

function testEveryCaseAndSectorHasNonnegativeNormalizedDwell(testCase)
Ts=1e-4; vectors=zhou_ipmsm.inverter.voltage_vectors(48,2/3);
verify_command(testCase,zhou_ipmsm.modulation.case1_command(Ts,vectors),Ts);
for active=1:6
    for duty=[.1 .5 .9]
        c=zhou_ipmsm.modulation.case2_command( ...
            duty*vectors.ab_V(active+1,:),active,Ts,vectors,1e-12);
        verify_command(testCase,c,Ts);
    end
end
low=[1 3 3 5 5 1]; high=[2 2 4 4 6 6];
for sector=1:6
    for duties=[.1 .3;.2 .2;.4 .1].'
        ref=duties(1)*vectors.ab_V(low(sector)+1,:)+ ...
            duties(2)*vectors.ab_V(high(sector)+1,:);
        c=zhou_ipmsm.modulation.case3_command(ref,Ts,vectors,1e-12,1e-12);
        verify_command(testCase,c,Ts);
    end
end
end

function verify_command(testCase,c,Ts)
verifyTrue(testCase,c.legal);
verifyGreaterThanOrEqual(testCase,min(c.sequence_durations_s),0);
verifyEqual(testCase,sum(c.sequence_durations_s),Ts,'AbsTol',100*eps(Ts));
verifyEqual(testCase,numel(c.sequence_vector_ids),numel(c.sequence_durations_s));
end
