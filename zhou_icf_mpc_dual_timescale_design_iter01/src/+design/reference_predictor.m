function prediction = reference_predictor(i_k_dq,u_pending_k_dq, ...
        u_selected_k_dq,F_post,F_previous,alpha_post,decision_gate_latched,cfg)
%REFERENCE_PREDICTOR Exact Zhou two-step index skeleton, reference only.
% pending(k) acts over k->k+1; final post-S2 selected(k) acts over k+1->k+2.

arguments
    i_k_dq (2,1) double {mustBeFinite}
    u_pending_k_dq (2,1) double {mustBeFinite}
    u_selected_k_dq (2,1) double {mustBeFinite}
    F_post (2,1) double {mustBeFinite}
    F_previous (2,1) double {mustBeFinite}
    alpha_post (2,1) double {mustBePositive,mustBeFinite}
    decision_gate_latched (1,1) logical
    cfg struct = design.project_parameter()
end

F_pred = F_post;
if decision_gate_latched
    F_pred = F_post+cfg.rho_F.*(F_post-F_previous);
end
i_k1 = i_k_dq+cfg.Ts_s*(F_pred+alpha_post.*u_pending_k_dq);
i_k2 = i_k1+cfg.Ts_s*(F_pred+alpha_post.*u_selected_k_dq);
prediction = struct('i_hat_k1_given_k_A',i_k1, ...
    'i_hat_k2_given_k_A',i_k2,'F_pred_A_per_s',F_pred, ...
    'alpha_used_A_per_Vs',alpha_post,'step_count',2, ...
    'future_actual_current_used',false,'oracle_parameter_used',false, ...
    'selected_voltage_role',"post_S2_final_selected(k)");
end
