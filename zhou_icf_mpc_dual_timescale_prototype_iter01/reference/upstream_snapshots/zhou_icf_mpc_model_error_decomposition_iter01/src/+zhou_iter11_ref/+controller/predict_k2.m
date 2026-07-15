function current_k2 = predict_k2(current_k1, Fhat_k, candidate_voltage_dq, alpha_dq, Ts)
%PREDICT_K2 Paper equation (4).

current_k2 = current_k1(:) + Ts * (Fhat_k(:) + ...
    alpha_dq(:) .* candidate_voltage_dq(:));
end

