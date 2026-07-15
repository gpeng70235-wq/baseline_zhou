function tests = test_s2_applied_voltage_usage
tests = functiontests(localfunctions);
end

function test_target_voltage_cannot_enter_F_update(testCase)
cfg=design.project_parameter();
gate=struct('g_F_dq',[true;true],'g_decision_latched',false);
alpha=cfg.alpha_initial_A_per_Vs;
[F1,~,d1]=design.reference_F_update([0;0],[0;0],[5000;5000], ...
    [2;3],alpha,gate,cfg);
[F2,~,~]=design.reference_F_update([0;0],[0;0],[5000;5000], ...
    [2;3],alpha,gate,cfg);
verifyEqual(testCase,F1,F2,'AbsTol',0);
verifyEqual(testCase,d1.used_voltage_role,"u_app(k-1)_post_S2_equivalent");
verifyEqual(testCase,d1.F_meas_A_per_s,[5000;5000]-alpha.*[2;3]);
end

function test_S2_trigger_alone_does_not_freeze(testCase)
cfg=design.project_parameter();obs=base_obs();obs.s2.triggered=true;
[g,d]=design.reference_gate_logic(obs,cfg);
verifyTrue(testCase,g.g_s2);verifyTrue(testCase,all(g.g_alpha_dq));
verifyTrue(testCase,d.s2_trigger_did_not_force_freeze);
obs.s2.reconstruction_valid=false;
[g,~]=design.reference_gate_logic(obs,cfg);
verifyFalse(testCase,g.g_s2);verifyFalse(testCase,any(g.g_alpha_dq));
end

function o=base_obs
o=struct('u_hp_dq_V',[2;2],'window_energy_dq_V2',[20;20], ...
 'regressor_rcond_dq',[0.2;0.2],'residual_jump_dq_A_per_s',[1;1], ...
 'zero_vector_run',0,'history_valid',true,'slow_tick',true, ...
 'decision_gate_latched',false);
o.s2=struct('triggered',false,'reconstruction_valid',true, ...
 'durations_valid',true,'log_complete',true,'clipped_unknown',false, ...
 'voltage_utilization_ratio',0.5);
o.decision=struct('native_selection_valid',true,'Jd_pred_A2',0.1, ...
 'Jq_pred_A2',0.1,'Jd_limit_A2',0.16,'Jq_limit_A2',0.16,'mode_gap_A2',1);
end
