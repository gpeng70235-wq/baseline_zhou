function tests = test_decision_gate
tests = functiontests(localfunctions);
end

function test_near_boundary_sets_next_latch_only(testCase)
cfg=design.project_parameter();obs=base_obs();
obs.decision.Jd_pred_A2=0.15;
[g,d]=design.reference_gate_logic(obs,cfg);
verifyTrue(testCase,g.g_decision_next);
verifyFalse(testCase,g.g_decision_latched);
verifyEqual(testCase,d.m_J_A2,0.01,'AbsTol',1e-12);
obs.decision.Jd_pred_A2=0.05;obs.decision.Jq_pred_A2=0.05;
[g,~]=design.reference_gate_logic(obs,cfg);
verifyFalse(testCase,g.g_decision_next);
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
