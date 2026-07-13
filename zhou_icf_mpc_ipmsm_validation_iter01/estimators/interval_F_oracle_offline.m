function [oracle,audit] = interval_F_oracle_offline(trace,alpha_dq,Ts)
%INTERVAL_F_ORACLE_OFFLINE Noncausal interval-F lower bound for diagnostics.
% This entry point is intentionally named OFFLINE. It consumes the future
% endpoint of each interval and must never be called by an online controller.

arguments
    trace table
    alpha_dq double
    Ts (1,1) double {mustBePositive,mustBeFinite}
end

[oracle,audit] = zhou_validation.calculate_F_interval_oracle( ...
    trace,alpha_dq,Ts);
audit.entry_point = "interval_F_oracle_offline";
audit.online = false;
audit.noncausal = true;
audit.role = "offline_lower_bound_only";
end
