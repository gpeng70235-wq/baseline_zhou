# Phase Coherence Report

Amplitude and phase are evaluated per complete electrical cycle on the uniform-angle fits. Calibration and held-out validation cycles are never the same cycles.

## Preregistered stability gates

A case/axis/order passes only when full-window peak SNR >= 6 dB, cycle amplitude CV <= 30%, circular R >= 0.7, and calibration-to-validation amplitude/phase remain within the registered bounds.

## Results

- Stable 6th-order ENGINEERING_PRIMARY cases (at least one axis): **11**.
- Stable 12th-order ENGINEERING_PRIMARY cases (at least one axis): **11**.
- Leave-one-cycle-out 6+12 positive-RMS transfers: **39/39**; median reduction `14.080%`.
- Valid same-speed leave-one-case-out 6+12 positive transfers: **6/10**; median reduction `3.222%`.

Frequency synchronization is assessed from fixed order times measured electrical frequency; fixed-Hz alternatives are separated by the 300/400/500 rpm groups. No post-hoc order replaces the preregistered 6 and 12.
