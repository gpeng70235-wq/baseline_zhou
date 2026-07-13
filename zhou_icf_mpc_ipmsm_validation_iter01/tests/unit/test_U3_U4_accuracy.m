function tests = test_U3_U4_accuracy
tests = functiontests(localfunctions);
end

function testMidpointU3MatchesExactRotatingFrameIntegral(testCase)
[project,~]=validation_test_fixture("P1"); p=project.paper; Ts=p.Ts_s;
vectors=zhou_ipmsm.inverter.voltage_vectors(48,2/3);
commands={zhou_ipmsm.modulation.case1_command(Ts,vectors), ...
    zhou_ipmsm.modulation.case2_command(.4*vectors.ab_V(2,:),1,Ts,vectors,1e-12), ...
    zhou_ipmsm.modulation.case3_command(.3*vectors.ab_V(2,:)+ ...
        .2*vectors.ab_V(3,:),Ts,vectors,1e-12,1e-12)};
errors=[]; theta=.23;
for speed=[100 300 500]
    omega=speed*2*pi/60*p.pole_pairs;
    for k=1:numel(commands)
        U3=zhou_ipmsm.controller.sequence_equivalent_dq_voltage( ...
            commands{k},vectors,theta,omega,1,Ts,"execution_segment_midpoint");
        U4=exact_average(commands{k},vectors,theta,omega,1,Ts);
        errors(end+1,1)=norm(U3-U4); %#ok<AGROW>
    end
end
verifyLessThanOrEqual(testCase,max(errors),project.thresholds.U3_U4_max_error_V);
verifyLessThanOrEqual(testCase,mean(errors),project.thresholds.U3_U4_mean_error_V);
verifyGreaterThan(testCase,max(errors),0, ...
    'The independent exact oracle should detect finite midpoint quadrature error.');
end

function average=exact_average(command,vectors,theta,omega,delay,Ts)
d=command.sequence_durations_s(:); ids=command.sequence_vector_ids(:);
starts=[0;cumsum(d(1:end-1))]; average=[0;0];
for k=1:numel(d)
    if d(k)==0, continue; end
    ab=vectors.ab_V(ids(k)+1,:); t0=delay*Ts+starts(k); t1=t0+d(k);
    if omega==0
        integral=d(k)*zhou_ipmsm.math.park(ab,theta);
    else
        phi0=theta+omega*t0; phi1=theta+omega*t1;
        int_cos=(sin(phi1)-sin(phi0))/omega;
        int_sin=(cos(phi0)-cos(phi1))/omega;
        integral=[ab(1)*int_cos+ab(2)*int_sin; ...
            -ab(1)*int_sin+ab(2)*int_cos];
    end
    average=average+integral/Ts;
end
end
