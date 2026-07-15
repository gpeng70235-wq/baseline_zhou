# Window Selection Protocol

Selection is deterministic and uses registered phase labels, termination status, electrical speed, and complete-cycle counts. No residual amplitude or visible peak enters selection.

## Rules

1. Start at the first upstream-registered `steady` sample.
2. Keep the largest integer number of electrical cycles from that point.
3. Require at least 3 cycles, complete 1198-row termination, non-stress range, nonzero electrical frequency, and Nyquist support through order 20.
4. Require speed CV <= 1.00% for time FFT.
5. Core and parameter cases are ENGINEERING_PRIMARY. Dynamic cases are retained only as SECONDARY_DYNAMIC; stress and early termination evidence cannot lead the conclusion.
6. Complete cycles are split in time order: floor(N/2) calibration cycles and the remaining cycles held out for validation.

## Outcome

- Valid order-tracking windows: **14**.
- Valid ENGINEERING_PRIMARY windows: **11**.
- Valid complete electrical cycles: **49** (primary: **39**).
- Calibration/validation cycles: **20 / 29**.

Every excluded case and reason is retained in `results/summary/window_registry.csv`.
