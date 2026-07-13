function tests = test_axis_specific_alpha
tests = functiontests(localfunctions);
end

function testControllerRectangleUsesIndependentAxes(testCase)
[cfg,input,p]=controller_fixture("axis_specific");
out=zhou_ipmsm.controller.icf_mpc_step(input,cfg);
verifyEqual(testCase,[out.geometry.rect.alpha_d;out.geometry.rect.alpha_q], ...
    [1/p.Ld_H;1/p.Lq_H],'RelTol',1e-14);
verifyNotEqual(testCase,out.geometry.rect.alpha_d,out.geometry.rect.alpha_q);
verifyNotEqual(testCase,out.geometry.rect.half_dq(1),out.geometry.rect.half_dq(2));
end

function [cfg,input,p]=controller_fixture(mode)
p=ipmsm_parameters(); a=implementation_assumptions();
if mode=="axis_specific"
    p.alpha_d=1/p.Ld_H; p.alpha_q=1/p.Lq_H;
else
    p.alpha_d=1/p.Ls_H; p.alpha_q=1/p.Ls_H;
end
vectors=zhou_ipmsm.inverter.voltage_vectors(48,2/3);
pending=zhou_ipmsm.modulation.case1_command(p.Ts_s,vectors);
pending.reference_dq_at_selection=[0;0]; pending.theta_at_selection=0;
cfg=struct('paper',p,'assumptions',a,'vectors',vectors, ...
    'Jd_limit',.16,'Jq_limit',.16);
input=struct('current_dq',[0;0],'previous_current_dq',[0;0], ...
    'last_applied_voltage_dq',[0;0],'pending_voltage_dq',[0;0], ...
    'pending_command',pending,'omega_e',100,'pending_vector_id',0, ...
    'estimator_history_valid',false,'reference_dq',[0;0],'theta_e',.2, ...
    'current_history_dq',zeros(2,a.estimator_window_samples+1), ...
    'applied_history_dq',zeros(2,a.estimator_window_samples));
end
