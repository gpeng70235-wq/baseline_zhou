# Estimator mapping

The default online estimator is the unchanged Iteration 11 Fliess–Join algebraic integral with five applied-voltage intervals. F history uses the actually applied ideal command, not the selected future command.

The basic linear ESO is a comparison-only online baseline. At cycle `k`, its state is `i_hat(k), F_hat(k)`; the current pending voltage `u(k)` updates the next state, while only causal `F_hat(k)` enters the controller. Poles 0.15, 0.30, and 0.50 are all reported.

The interval Oracle consumes a future endpoint and exact interval voltage. It is noncausal, offline, and only a lower-bound/counterfactual diagnostic; it is prohibited from every online path.
