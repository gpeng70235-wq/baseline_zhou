function state = estimator_initialize(p)
%ESTIMATOR_INITIALIZE Reset state without reading plant parameters.
state.alpha = p.alpha_initial;
state.F = p.F_initial;
state.F_previous = p.F_initial;
state.F_pred = p.F_initial;
state.u_bar = [0;0];
state.y_bar = [0;0];
state.u_hp_window = zeros(2,p.excitation_window);
state.window_count = 0;
state.residual_previous = [0;0];
state.freeze_count = zeros(2,1);
state.good_window_count = zeros(2,1);
state.projection_hits = zeros(2,1);
state.update_count = zeros(2,1);
state.zero_vector_run = 0;
state.history_valid = false;
state.sample_index = uint64(0);
state.decision_gate_latched = false;
state.status = ["startup";"startup"];
state.reset_count = 0;
state.reacquire_count = zeros(2,1);
state.rls_P = repmat(p.rls_P_initial,1,1,2);
end
