# Frame patch inheritance audit

For segment `j`, the retained candidate transform is evaluated at

```text
theta_j = theta_sample + omega_e (delay*Ts + segment_start_j + duration_j/2).
```

The equivalent voltage is the duration-weighted sum of the Park-transformed switching vectors. The pending command uses `delay=0`; the newly selected command uses `delay=1`; and the geometry rectangle uses `theta_sample+1.5*omega_e*Ts`, matching the Iteration 11 execution timing.

`run_probe_case` actually integrates the pending command, records its applied legality, then queues the selected command. It separately checks the selected command, so the last selected command cannot escape validation.

`test_frame_angle_patch_preserved` compares the implementation to an independently accumulated per-segment midpoint oracle, checks pending/selected delay values, checks the geometry angle, and confirms that the legacy single-selection-angle mode is observably different.

Status: **PASS** for the v1.1 code path.
