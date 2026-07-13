# Source inheritance audit

The executable reference package is a namespace-adapted copy of the byte-for-byte snapshot under `reference/iter11/source_snapshot`. The IPMSM package independently copies the same controller/geometry/modulation closure and adapts only plant equations, torque, alpha selection, estimator comparison hook, configurable RK4 step, and audit logging.

Probe code is equation/reference evidence only. Old summaries, plots, logs, and run IDs are excluded from runtime. See `docs/baseline_inheritance_mapping.md` for every file.
