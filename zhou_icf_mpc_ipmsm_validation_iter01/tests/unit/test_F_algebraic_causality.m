function tests = test_F_algebraic_causality
tests = functiontests(localfunctions);
end

function testAlgebraicEstimatorUsesOnlyPastAppliedWindow(testCase)
Ts=1e-4; N=5; alpha=[1250;1/1.2e-3];
Ftrue=[7;-11]; u=repmat([2;-3],1,N); rate=Ftrue+alpha.*u(:,1);
t=(0:N)*Ts; y0=[-.4;2.1]; current=y0+rate.*t;
actual=algebraic_F_iter11(current,u,alpha,Ts);
reference=zhou_ipmsm.controller.estimate_F_algebraic(current,u,alpha,Ts);
verifyEqual(testCase,actual,reference,'AbsTol',1e-10);
verifyEqual(testCase,actual,Ftrue,'AbsTol',1e-8);

% A future sample is deliberately changed by an enormous amount. Calling
% the estimator on the same causal N+1/N prefix must remain bit-identical.
future_current=[current,current(:,end)+1e6];
future_voltage=[u,[1e6;-1e6]];
again=algebraic_F_iter11(future_current(:,1:N+1), ...
    future_voltage(:,1:N),alpha,Ts);
verifyEqual(testCase,again,actual,'AbsTol',0);
verifyError(testCase,@() algebraic_F_iter11(current(:,1:N),u,alpha,Ts), ...
    'ZhouIPMSM:EstimatorHistory');
end
