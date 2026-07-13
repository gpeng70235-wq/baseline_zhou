function [Fhat,state_next,audit] = basic_ESO_F(state,current_dq, ...
        applied_u_dq,alpha_dq,Ts,pole)
%BASIC_ESO_F Causal two-state linear ESO used only as a comparison baseline.
% At controller cycle k, state contains i_hat(k),F_hat(k), current_dq is i(k),
% and applied_u_dq is the already-known pending voltage that will execute in
% interval k. F_hat(k) is exposed to the controller; state_next is k+1.

arguments
    state
    current_dq (2,1) double {mustBeFinite}
    applied_u_dq (2,1) double {mustBeFinite}
    alpha_dq (2,1) double {mustBePositive,mustBeFinite}
    Ts (1,1) double {mustBePositive,mustBeFinite}
    pole (1,1) double {mustBeGreaterThan(pole,0),mustBeLessThan(pole,1)}
end

initialized = isempty(state);
if initialized
    i_hat = current_dq;
    F_previous = zeros(2,1);
    sample_count = 0;
else
    assert(isstruct(state) && isfield(state,'i_hat') && ...
        isfield(state,'F_hat'), 'ZhouValidation:ESOState', ...
        'ESO state must be empty or contain i_hat and F_hat.');
    i_hat = state.i_hat(:);
    F_previous = state.F_hat(:);
    assert(numel(i_hat)==2 && numel(F_previous)==2 && ...
        all(isfinite([i_hat;F_previous])), 'ZhouValidation:ESOState', ...
        'ESO i_hat and F_hat must each contain two finite values.');
    if isfield(state,'sample_count')
        sample_count = state.sample_count;
    else
        sample_count = 0;
    end
end

% This mapping matches config/estimator_definitions.m: the forward-Euler
% first-order observer pole is 1-omega0*Ts = pole.
omega0 = (1-pole)/Ts;
beta01 = 2*omega0*Ts;
beta02 = omega0^2*Ts;
innovation = i_hat-current_dq;

i_hat_next = i_hat + Ts*(F_previous+alpha_dq.*applied_u_dq) - ...
    beta01*innovation;
F_next = F_previous-beta02*innovation;

% F_hat(k) is causal and available before interval k executes. F_next is
% retained only in the state that will be consumed at controller cycle k+1.
Fhat = F_previous;
state_next = struct('i_hat',i_hat_next,'F_hat',F_next, ...
    'sample_count',sample_count+1);

audit = struct();
audit.estimator = "basic_ESO";
audit.comparison_only = true;
audit.initialized_this_call = initialized;
audit.pole = pole;
audit.omega0_rad_s = omega0;
audit.beta01 = beta01;
audit.beta02 = beta02;
audit.innovation_dq_A = innovation;
audit.applied_u_dq_V = applied_u_dq;
audit.F_output_timing = "F_hat(k) available to controller at cycle k";
audit.input_timing = "pending/applied u(k) for interval k";
audit.state_next_timing = "i_hat(k+1), F_hat(k+1)";
audit.causal = true;
audit.online = true;
audit.uses_future_measurement = false;
end
