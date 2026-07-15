# Residual Dataset Schema

Each row is one decision index k with explicit prediction/selected/pending/applied/actual indices. `residual_valid` is false rather than silently dropping unavailable or failed data. Plant scale columns are offline stratification only.

Online E2 features are frozen in `implementation_assumptions.scheduled_bound_feature_names` and pass `audit_no_future_features`.
