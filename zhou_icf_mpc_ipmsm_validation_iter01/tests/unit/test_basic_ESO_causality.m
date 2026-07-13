function tests = test_basic_ESO_causality
tests = functiontests(localfunctions);
end

function testESOIsDeterministicStatefulAndPresentCausal(testCase)
Ts=1e-4; alpha=[1250;1/1.2e-3]; pole=.30;
current=[-.2;4.0]; voltage=[3;-5];
[F1,state1]=basic_ESO_F([],current,voltage,alpha,Ts,pole);
[F1_repeat,state1_repeat]=basic_ESO_F([],current,voltage,alpha,Ts,pole);
verifyEqual(testCase,F1_repeat,F1,'AbsTol',0);
verifyEqual(testCase,state1_repeat,state1);
verifySize(testCase,F1,[2 1]);
verifyTrue(testCase,all(isfinite(F1)));
verifyTrue(testCase,isstruct(state1));

[Fa,state_a]=basic_ESO_F(state1,current+[.1;-.2],voltage,alpha,Ts,pole);
[Fb,state_b]=basic_ESO_F(state1,current+[-.3;.4],voltage,alpha,Ts,pole);
verifyTrue(testCase,all(isfinite([Fa;Fb])));
verifyGreaterThan(testCase,norm(Fa-Fb)+state_distance(state_a,state_b),0);
omega0=(1-pole)/Ts; beta01=2*omega0*Ts; beta02=omega0^2*Ts;
measurement=current+[.1;-.2]; innovation=state1.i_hat-measurement;
expected_i=state1.i_hat+Ts*(state1.F_hat+alpha.*voltage)-beta01*innovation;
expected_F=state1.F_hat-beta02*innovation;
verifyEqual(testCase,Fa,state1.F_hat,'AbsTol',0);
verifyEqual(testCase,state_a.i_hat,expected_i,'AbsTol',1e-12);
verifyEqual(testCase,state_a.F_hat,expected_F,'AbsTol',1e-9);

% Reusing the identical prior state/input after unrelated calls proves that
% no hidden persistent/future state contaminates the online estimator.
[Fa_repeat,state_a_repeat]=basic_ESO_F(state1,current+[.1;-.2],voltage,alpha,Ts,pole);
verifyEqual(testCase,Fa_repeat,Fa,'AbsTol',0);
verifyEqual(testCase,state_a_repeat,state_a);
end

function value=state_distance(a,b)
names=intersect(fieldnames(a),fieldnames(b)); value=0;
for k=1:numel(names)
    x=a.(names{k}); y=b.(names{k});
    if isnumeric(x) && isnumeric(y) && isequal(size(x),size(y))
        value=value+norm(double(x(:))-double(y(:)));
    end
end
end
