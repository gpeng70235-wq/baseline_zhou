# Counterfactual Correction Report

These results are **offline counterfactual constraint classification**, not closed-loop control performance. The original B0 trajectory, selected vectors, plant, limits, and S2 decisions are unchanged.

## Isolation

Coefficients are fitted only on the earlier complete calibration cycles of each case. Held-out actual currents are used solely to score residuals and actual constraint truth; they never tune the correction.
The corrected predictions are `i_pred_B0 + e_periodic`, followed by recomputation of fixed `Jd/Jq=0.16 A^2` classifications.

## ENGINEERING_PRIMARY held-out results

- **B0**: residual RMS `0.0386241933 A`; RMS change `+0.000%`; false-safe `3.573592%` (relative change `-0.000%`); false-alarm change `+0.000000 pp`; max FS run `2`.
- **mean_trend**: residual RMS `0.0388940528 A`; RMS change `-0.699%`; false-safe `3.391884%` (relative change `-5.085%`); false-alarm change `+0.090854 pp`; max FS run `2`.
- **6**: residual RMS `0.0363207732 A`; RMS change `+5.964%`; false-safe `2.967898%` (relative change `-16.949%`); false-alarm change `+0.151423 pp`; max FS run `2`.
- **12**: residual RMS `0.0363861775 A`; RMS change `+5.794%`; false-safe `3.028468%` (relative change `-15.254%`); false-alarm change `+0.272562 pp`; max FS run `2`.
- **6+12**: residual RMS `0.0339279459 A`; RMS change `+12.159%`; false-safe `2.665051%` (relative change `-25.424%`); false-alarm change `+0.454270 pp`; max FS run `2`.

Per-case and cohort results are complete in the two registered counterfactual CSVs. A candidate bank was not reconstructed, so no offline ranking is presented as native Zhou decision behavior.
Case-level rows: **70**. Future validation data were not used for coefficient updates.
