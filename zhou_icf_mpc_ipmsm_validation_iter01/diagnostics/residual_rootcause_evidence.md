# Residual root-cause evidence

- run_id: `20260713_084757_ipmsm_validation`
- worst case: `500rpm_low_10A`

All transition ratios and correlations are associations, not causal estimates. The interval oracle is noncausal and used only as a lower bound.

| statistic | value | scope |
|---|---:|---|
| P1_minus_P0_d_prediction_RMSE_A | 0.00321226594 | six_condition_P1_vs_P0 |
| P1_minus_P0_q_prediction_RMSE_A | -0.00322668284 | six_condition_P1_vs_P0 |
| P1_vs_P0_d_residual_ratio | 1.62403644 | six_condition_P1_vs_P0 |
| negative_id_Fd_oracle_RMSE_delta | 30.5061129 | three_condition_id_-6_vs_0 |
| sector_transition_error_ratio | 1.21729137 | worst_case_cycle_association |
| case_transition_error_ratio | 1.90508321 | worst_case_cycle_association |
| command_transition_error_ratio | 1.30974383 | worst_case_cycle_association |
| prediction_error_voltage_utilization_correlation | 0.181505614 | worst_case_cycle_association |
| axis_specific_mean_d_RMSE_delta_A | -0.0372589768 | six_condition_alpha_pair |
| offline_oracle_prediction_improvement | 0.214421995 | five_condition_offline_counterfactual |
| best_ESO_prediction_improvement | -0.00768638488 | five_condition_online_ESO |
