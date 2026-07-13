# Metric definitions

- Tracking RMSE/bias/max error use the declared steady interval.
- k+1 and k+2 prediction errors are aligned to future plant endpoints, never the same-row current.
- Actual exceedance is `max(0, abs(i_ref-i_plant(k+2))-sqrt(J_limit))` in amperes. Numerical, strict, and engineering events use `1e-9`, `0.01`, and `0.1 A` thresholds.
- `illegal_command=1` means selected or applied vector/dwell contract is illegal; this corrects the inverted legacy audit field.
- THD is nonfundamental RMS divided by fundamental RMS on a resampled integer-cycle window. Fundamental peak/RMS, harmonic power, nonfundamental power, window endpoints, cycles, and samples are saved.
- Switching frequency uses applied sequence transitions, six devices, and steady-window duration.
- Voltage utilization is selected equivalent dq magnitude divided by `(2/3)Vdc`; saturation flag begins at 0.98.
- U3/U4 numerical closure gates the same selected sequence: segment-midpoint rotating-frame approximation versus exact rotating-frame integral. Pending and selected commands remain separate log fields.
