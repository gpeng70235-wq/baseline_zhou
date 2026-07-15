function V = compute_V_terms(reference_dq, predicted_k1, Fhat_k, Ts)
%COMPUTE_V_TERMS Vd/Vq definitions beneath paper equation (7).

V = reference_dq(:) - predicted_k1(:) - Ts * Fhat_k(:);
end

