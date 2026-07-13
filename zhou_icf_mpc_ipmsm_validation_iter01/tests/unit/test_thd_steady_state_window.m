function tests = test_thd_steady_state_window
tests = functiontests(localfunctions);
end

function testIntegerCycleWindowExcludesStartupAndReportsComponents(testCase)
Ts=1e-4; f=100; t=(0:Ts:.2-Ts).'; start=.1; stop=.2;
fundamental_rms=3; harmonic_rms=.3;
signal=sqrt(2)*fundamental_rms*sin(2*pi*f*t)+ ...
    sqrt(2)*harmonic_rms*sin(2*pi*3*f*t+.2);
startup=t<start;
signal(startup)=signal(startup)+20*exp(-20*t(startup)).*sin(2*pi*17*t(startup));
[result,spectrum,windowed]=zhou_validation.calculate_steady_state_thd( ...
    signal,t,f,start,stop,40);
required={'thd_percent','fundamental_rms_A','harmonic_power_A2', ...
    'nonfundamental_power_A2','steady_window_start_s', ...
    'steady_window_end_s','electrical_cycles','window_samples'};
verifyTrue(testCase,isstruct(result) && isscalar(result));
verifyTrue(testCase,all(isfield(result,required)));
verifyEqual(testCase,result.thd_percent,10,'AbsTol',.05);
verifyEqual(testCase,result.fundamental_rms_A,fundamental_rms,'AbsTol',1e-3);
verifyEqual(testCase,sqrt(result.harmonic_power_A2),harmonic_rms,'AbsTol',1e-3);
verifyEqual(testCase,result.harmonic_power_A2,harmonic_rms^2,'AbsTol',1e-3);
verifyEqual(testCase,result.steady_window_start_s,start,'AbsTol',Ts/2);
verifyEqual(testCase,result.steady_window_end_s,stop,'AbsTol',Ts/2);
verifyEqual(testCase,result.electrical_cycles,10,'AbsTol',1e-12);
verifyEqual(testCase,result.window_samples,1000);
verifyEqual(testCase,height(windowed),result.window_samples);
third=spectrum.harmonic_order==3;
verifyEqual(testCase,spectrum.rms_A(third),harmonic_rms,'AbsTol',1e-3);
end
