function [F_post,F_pred,diagnostic] = reference_F_update( ...
        F_prior,F_previous,y_dq,u_app_previous_dq,alpha_post,gate,cfg)
%REFERENCE_F_UPDATE Fast lumped-term update using actual applied voltage.

arguments
    F_prior (2,1) double {mustBeFinite}
    F_previous (2,1) double {mustBeFinite}
    y_dq (2,1) double {mustBeFinite}
    u_app_previous_dq (2,1) double {mustBeFinite}
    alpha_post (2,1) double {mustBeFinite}
    gate struct
    cfg struct = design.project_parameter()
end

assert(isfield(gate,'g_F_dq') && isfield(gate,'g_decision_latched'), ...
    'DualTimescale:MissingFGate','F gate fields are missing.');
enabled = logical(gate.g_F_dq(:));
F_meas = y_dq-alpha_post.*u_app_previous_dq;
F_post = F_prior;
F_post(enabled) = F_prior(enabled)+cfg.beta_F(enabled).* ...
    (F_meas(enabled)-F_prior(enabled));
F_post = min(cfg.max_abs_F_A_per_s,max(-cfg.max_abs_F_A_per_s,F_post));
trend = cfg.rho_F.*(F_post-F_previous);
if gate.g_decision_latched
    F_pred = F_post+trend;
else
    F_pred = F_post;
end
diagnostic = struct('F_meas_A_per_s',F_meas,'updated',enabled, ...
    'trend_A_per_s',trend,'trend_enabled',logical(gate.g_decision_latched), ...
    'used_voltage_role',"u_app(k-1)_post_S2_equivalent");
end
