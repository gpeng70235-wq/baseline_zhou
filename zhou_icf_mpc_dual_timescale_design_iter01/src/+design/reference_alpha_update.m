function [alpha_post,diagnostic] = reference_alpha_update( ...
        alpha_prior,u_hp_dq,y_hp_dq,gate,cfg)
%REFERENCE_ALPHA_UPDATE Slow normalized projected-gradient update.
% Inputs at control row k contain only i(k), i(k-1), and u_app(k-1)
% derived quantities. alpha_post is therefore causal and may be used at k.

arguments
    alpha_prior (2,1) double {mustBeFinite}
    u_hp_dq (2,1) double {mustBeFinite}
    y_hp_dq (2,1) double {mustBeFinite}
    gate struct
    cfg struct = design.project_parameter()
end

assert(isfield(gate,'g_alpha_dq') && isfield(gate,'alpha_step_scale'), ...
    'DualTimescale:MissingAlphaGate','Alpha gate fields are missing.');
enabled = logical(gate.g_alpha_dq(:));
assert(numel(enabled)==2,'DualTimescale:AlphaGateDimension', ...
    'g_alpha_dq must be 2-by-1.');
e_alpha = y_hp_dq-alpha_prior.*u_hp_dq;
denominator = cfg.epsilon_alpha_V2+u_hp_dq.^2;
increment = gate.alpha_step_scale.*cfg.gamma_alpha.*u_hp_dq.*e_alpha./denominator;
raw = alpha_prior;
raw(enabled) = alpha_prior(enabled)+increment(enabled);
alpha_post = min(cfg.alpha_max_A_per_Vs,max(cfg.alpha_min_A_per_Vs,raw));
assert(all(isfinite(alpha_post)),'DualTimescale:NonfiniteAlpha', ...
    'Projected alpha must remain finite.');
diagnostic = struct('e_alpha_A_per_s',e_alpha,'denominator_V2',denominator, ...
    'raw_A_per_Vs',raw,'increment_A_per_Vs',increment, ...
    'projected',raw~=alpha_post,'updated',enabled);
end
