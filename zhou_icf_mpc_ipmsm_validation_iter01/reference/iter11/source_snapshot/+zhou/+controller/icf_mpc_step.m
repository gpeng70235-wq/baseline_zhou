function output = icf_mpc_step(input, cfg)
%ICF_MPC_STEP Equations (2)-(15) and Fig. 3 core controller.

alpha = [cfg.paper.alpha_d; cfg.paper.alpha_q];
if cfg.assumptions.estimator=="fliess_join_2013_algebraic_integral"
    Fhat=zhou.controller.estimate_F_algebraic(input.current_history_dq, ...
        input.applied_history_dq,alpha,cfg.paper.Ts_s);
else
    Fhat = zhou.controller.estimate_F(input.current_dq, ...
        input.previous_current_dq, input.last_applied_voltage_dq, alpha, ...
        cfg.paper.Ts_s, input.estimator_history_valid, ...
        cfg.assumptions.estimator_initial_F_dq(:));
end

if cfg.assumptions.candidate_voltage_frame_mode=="execution_segment_midpoint"
    pending_voltage=zhou.controller.sequence_equivalent_dq_voltage(input.pending_command, ...
        cfg.vectors,input.theta_e,input.omega_e,0,cfg.paper.Ts_s,cfg.assumptions.candidate_voltage_frame_mode);
else
    pending_voltage=input.pending_voltage_dq;
end
predicted_k1 = zhou.controller.predict_k1(input.current_dq, Fhat, ...
    pending_voltage, alpha, cfg.paper.Ts_s);
V = zhou.controller.compute_V_terms(input.reference_dq, ...
    predicted_k1, Fhat, cfg.paper.Ts_s);

geometry_theta=input.theta_e;
if cfg.assumptions.candidate_voltage_frame_mode=="execution_segment_midpoint"
    geometry_theta=mod(input.theta_e+1.5*input.omega_e*cfg.paper.Ts_s,2*pi);
end
rect = zhou.geometry.build_rectangle(V(1), V(2), cfg.Jd_limit, ...
    cfg.Jq_limit, alpha(1), alpha(2), cfg.paper.Ts_s, geometry_theta, ...
    cfg.assumptions.geometry_tolerance);
geometry = zhou.geometry.analyze_rectangle(rect, cfg.vectors, ...
    cfg.assumptions.voltage_tolerance_V, ...
    cfg.assumptions.sector_angle_tolerance_rad, ...
    cfg.assumptions.duty_tolerance);
command = geometry.command;
command.reference_dq_at_selection = zhou.math.park(command.reference_ab_V,input.theta_e);
command.theta_at_selection = input.theta_e;
command.reference_dq_execution = zhou.controller.sequence_equivalent_dq_voltage(command, ...
    cfg.vectors,input.theta_e,input.omega_e,1,cfg.paper.Ts_s,cfg.assumptions.candidate_voltage_frame_mode);

predicted_k2 = zhou.controller.predict_k2(predicted_k1, Fhat, ...
    command.reference_dq_execution, alpha, cfg.paper.Ts_s);
[Jd_eq5, Jq_eq5] = zhou.controller.independent_costs( ...
    input.reference_dq, predicted_k2);
[Jd_eq7, Jq_eq7] = zhou.controller.independent_costs(input.reference_dq,predicted_k2);

crosscheck_error = max(abs([Jd_eq5-Jd_eq7, Jq_eq5-Jq_eq7]));
assert(crosscheck_error <= 1e-9, 'Zhou:CostCrosscheckFailure', ...
    'Equations (5) and (7) disagree by %.3g.', crosscheck_error);

output = struct();
output.command = command;
output.Fhat_dq = Fhat;
output.predicted_k1_dq = predicted_k1;
output.predicted_k2_dq = predicted_k2;
output.V_dq = V;
output.Jd = Jd_eq5;
output.Jq = Jq_eq5;
output.constraint_satisfied_d = Jd_eq5 <= cfg.Jd_limit + ...
    cfg.assumptions.constraint_tolerance;
output.constraint_satisfied_q = Jq_eq5 <= cfg.Jq_limit + ...
    cfg.assumptions.constraint_tolerance;
output.geometry = geometry;
output.cost_crosscheck_error = crosscheck_error;
output.pending_voltage_dq_used=pending_voltage;
output.selected_voltage_dq_used=command.reference_dq_execution;
output.geometry_theta=geometry_theta;
end
