function tests = test_RK4_switch_boundary_convergence
tests = functiontests(localfunctions);
end

function testConfiguredSubstepsRespectBoundariesAndConverge(testCase)
p=ipmsm_parameters(); p.Rs_Ohm=5*p.Rs_Ohm;
Ts=p.Ts_s; omega=4000; vectors=zhou_ipmsm.inverter.voltage_vectors(48,2/3);
command=zhou_ipmsm.modulation.case3_command(.35*vectors.ab_V(2,:)+ ...
    .25*vectors.ab_V(3,:),Ts,vectors,1e-12,1e-12);
steps=[2 1 .5 .25]*1e-6; states=zeros(3,numel(steps)); counts=zeros(size(steps));
for k=1:numel(steps)
    [states(:,k),~,audit]=zhou_ipmsm.model.integrate_command( ...
        [-5;13;.31],command,vectors,omega,p,Ts,1e-13,[0,0],steps(k));
    counts(k)=audit.rk4_substeps;
    verifyLessThanOrEqual(testCase,audit.time_residual_s,1e-13);
end
[reference,~,~]=zhou_ipmsm.model.integrate_command( ...
    [-5;13;.31],command,vectors,omega,p,Ts,1e-13,[0,0],.125e-6);
errors=vecnorm(states(1:2,:)-reference(1:2),2,1);
verifyGreaterThan(testCase,min(diff(counts)),0);
verifyLessThanOrEqual(testCase,errors(2),errors(1)+1e-12);
verifyLessThanOrEqual(testCase,errors(3),errors(2)+1e-12);
verifyLessThanOrEqual(testCase,errors(4),errors(3)+1e-12);
verifyLessThan(testCase,errors(4),errors(1));
end
