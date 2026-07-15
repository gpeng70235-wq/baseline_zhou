# Final Prototype Report

## Outcome

**C — dual-timescale primary mechanism failed the preregistered minimal gate.**

This is a five-case gate conclusion, not a fabricated 24-case result. P increased aggregate false-safe from 3.526239% to 3.753128% (relative reduction -6.434283%, negative means worse) and increased prediction vector RMS from 0.0613189 A to 0.132352 A.
P also terminated C07 at row 6 rather than the frozen row 31. False-alarm remained 0.000000%; alpha updates were finite and nonzero, so the failure is not a NaN-only artifact.

## Gate discipline

Full 24-case validation, ablation, sensitivity and final timing were not run. This is the required stop behavior after a failed minimal hard gate.

## Final algorithm

No final algorithm was formed; `FINAL_ALGORITHM_SPEC.md`, pseudocode, flow, parameters and final SHA files were intentionally not created.
