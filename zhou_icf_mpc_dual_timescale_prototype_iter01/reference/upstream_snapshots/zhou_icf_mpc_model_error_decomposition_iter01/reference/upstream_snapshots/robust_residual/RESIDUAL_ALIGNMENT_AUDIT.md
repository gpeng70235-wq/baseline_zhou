# Residual Alignment Audit

- definition: `e(k)=i_actual(k+2)-i_pred(k+2|k)`
- pending/applied index: `k+1`
- actual index: `k+2`
- tail handling: last two prediction rows omitted, never filled

- Calibration rows: `33966`; valid aligned: `33966`; invalid retained: `0`
- Validation rows: `43956`; valid aligned: `43956`; invalid retained: `0`
- Test rows: `57037`; valid aligned: `57037`; invalid retained: `0`

Selected sequence/duration at k is required to equal applied sequence/duration at k+1. No k+1 actual current is compared to a k+2 prediction.
