function tests = test_excitation_freeze
tests = functiontests(localfunctions);
end

function test_alpha_freezes_but_F_updates(testCase)
cfg=design.project_parameter(); obs=base_obs();
obs.u_hp_dq_V=[0;0];obs.window_energy_dq_V2=[0;0];
[gate,~]=design.reference_gate_logic(obs,cfg);
alpha0=cfg.alpha_initial_A_per_Vs;
[alpha1,~]=design.reference_alpha_update(alpha0,[0;0],[0;0],gate,cfg);
[F1,~,~]=design.reference_F_update([0;0],[0;0],[2000;-1000], ...
    [1;1],alpha1,gate,cfg);
verifyEqual(testCase,alpha1,alpha0);
verifyNotEqual(testCase,F1,[0;0]);
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
