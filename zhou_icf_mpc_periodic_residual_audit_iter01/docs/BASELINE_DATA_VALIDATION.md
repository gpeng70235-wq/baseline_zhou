# Baseline Data Validation

Result: **true (15/15 gates)**.

## Data source

The audit read the byte-identical frozen copy `reference/frozen_data/model_error_samples.csv`, whose source is the complete model-error snapshot inside the archived dual-timescale prototype. No B0 closed loop was rerun.
The five-case prototype B0 export was used only as an independent pointwise overlap check.

## Counts and rates

- Registered cases: **24**.
- Aligned samples: **24153**.
- ENGINEERING_PRIMARY (non-stress) false-safe: **3.029663699%**.
- REPRODUCTION_ALL false-safe: **3.059661326%**.
- Early termination cases: **5**.

## Timing and residual definition

Every row is the original prediction made at `k` for the state at `k+2`. The current state columns `id/iq` are at `k`; `id_actual/iq_actual` are the aligned actual values at `k+2`.
Residuals are `e_d(k)=id_actual(k+2)-id_pred(k+2|k)` and likewise for q. The maximum gap to the frozen `ed_P0/eq_P0` fields is `9.94950649646498e-14 A`.
The maximum squared-cost formula gap is `7.67386154620908e-13 A^2`. Jd/Jq limits remain fixed at `0.16 A^2`.

## Independent reproduction overlap

The separately generated prototype B0 export overlaps **4821** aligned rows; the maximum numeric gap is `1.20300214234703e-10`, with zero registered decision-flag mismatches.

Failed gates: ``. The workflow stops before spectral inference if any gate fails.
