function current_k1 = predict_k1(current_k, Fhat_k, pending_voltage_dq, alpha_dq, Ts)
%PREDICT_K1 Paper equation (3), including one-step digital delay.

current_k1 = current_k(:) + Ts * (Fhat_k(:) + ...
    alpha_dq(:) .* pending_voltage_dq(:));
end

