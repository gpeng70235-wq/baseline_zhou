function [Jd, Jq] = independent_costs(reference_dq, predicted_k2)
%INDEPENDENT_COSTS Paper equation (5).

error_dq = reference_dq(:) - predicted_k2(:);
Jd = error_dq(1)^2;
Jq = error_dq(2)^2;
end

