# Regression failure diagnosis

Two development failures were observed before v1.1:

1. The first test run passed 7/9. The torque test used an unrealistically small fixed `eps` tolerance, and zero-reference Case 1 returned before adding the common `legal`/state fields. The torque oracle and command contract were corrected.
2. The next P0 run had 15 tiny negative dwell values admitted by tolerance but counted by a strict `<0` metric. Dwell synthesis now clips only tolerance-scale roundoff, normalizes exactly to `Ts`, and the integrator independently rejects invalid sequences.

The tests were subsequently strengthened to cover the complete controller/geometry/frame/nonzero-`id` paths. Formal-run errors, if any, are written as one UTF-8 file per gate under `diagnostics/runtime_errors/`; the latest authoritative gate status is in `FINAL_IPMSM_PROBE_REPORT.md` and `logs/run_ledger.csv`.
