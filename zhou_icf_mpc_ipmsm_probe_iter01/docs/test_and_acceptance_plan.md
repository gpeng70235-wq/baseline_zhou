# Test and acceptance plan

The nine required test files cover path isolation, analytical SMPMSM reduction, explicit IPMSM equation signs, closed-form torque components, controller use of both alpha axes, the segment-midpoint frame oracle and pending queue, a nonzero-`id` closed loop, all six Case-3 sector sequences, Case 1/2/3 classification, duration contracts, and infeasible-command detection. The runner rejects a missing/empty suite and logs per-test diagnostics.

Runtime gates execute strictly in this order:

1. P0: `Ld=Lq`, zero reluctance torque, explicit SMPMSM derivative/torque oracle, reference contract, tracking/THD, command, geometry, and constraint checks.
2. P1: same common safety checks plus a minimum measured closed-loop saliency effect relative to a paired `Ld=Lq` run.
3. Alpha comparison: axis-specific and common-`Ls` runs must both be valid and differ by a configured effect size.
4. Negative-`id`: all four references must be valid and the endpoint must show a positive reluctance-torque gain for `Ld<Lq`.

Common limits are `RMSE <= 5 A`, phase-A FFT-bin THD `<= 0.20`, and zero applied/selected illegal commands, negative durations, constraint violations, out-of-rectangle references, or saturated requests. Exact values live only in `config/acceptance_thresholds.m`.
