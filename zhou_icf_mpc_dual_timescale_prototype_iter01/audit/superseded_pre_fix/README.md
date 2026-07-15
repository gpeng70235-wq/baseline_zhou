# Superseded pre-fix calibration artifacts

These files were generated before the trend indexing defect was found. The
implementation used `F_post(k)-F_post(k-2)` instead of the frozen
`F_post(k)-F_post(k-1)` definition. They are retained only for audit history
and must not be used as prototype evidence. The valid calibration is
`results/summary/parameter_calibration.csv`.
