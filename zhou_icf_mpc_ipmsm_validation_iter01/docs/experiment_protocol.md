# Experiment protocol

One formal invocation creates one `run_id`. Unit tests run first; A0 compares two independently executed closed loops at 100/300/500 rpm. A0 failure stops A1–A8. Later per-condition failures are recorded with the exact exception and the matrix continues; illegal commands are never silently projected or clamped.

A1–A3 use the probe-level 48 V, 5 ms ramp and ideal inverter with Iteration 11 geometry and algebraic F. A0 alone uses the frozen 84 V, 20 ms ramp and dead-time assumptions. A4/A5 modify only the plant; controller parameters remain nominal. All paired THD windows contain an integer number of electrical cycles and use unsmoothed waveform samples.
