function control = finalize_after_s2(control,input,cfg,estimator)
%FINALIZE_AFTER_S2 Re-evaluate k+2 only with the post-S2 final command.
u=zhou_ipmsm.controller.sequence_equivalent_dq_voltage(control.command,cfg.vectors, ...
    input.theta_e,input.omega_e,1,cfg.paper.Ts_s, ...
    cfg.assumptions.candidate_voltage_frame_mode);
[~,k2]=prototype.dual_timescale_predictor(input.current_dq,estimator.F_pred, ...
    estimator.alpha,control.pending_voltage_dq_used,u,cfg.paper.Ts_s);
[Jd,Jq]=zhou_ipmsm.controller.independent_costs(input.reference_dq,k2);
control.predicted_k2_dq=k2;control.selected_voltage_dq_used=u;
control.Jd=Jd;control.Jq=Jq;
control.constraint_satisfied_d=Jd<=cfg.Jd_limit+cfg.assumptions.constraint_tolerance;
control.constraint_satisfied_q=Jq<=cfg.Jq_limit+cfg.assumptions.constraint_tolerance;
control.Fhat_dq=estimator.F;control.Fpred_dq=estimator.F_pred;
control.alpha_dq=estimator.alpha;
end
