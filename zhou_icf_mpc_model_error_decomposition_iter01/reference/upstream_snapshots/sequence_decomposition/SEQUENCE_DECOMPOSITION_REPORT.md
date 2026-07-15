# Sequence Decomposition Report

## Result

- Final A–E decision: **B**.
- Frozen-F ultralocal segment replay equals the controller average prediction; model/F error dominates.
- Samples: **24153** across **24** representative cases.
- `e_sequence_ul/e_total` RMS ratio: **1.02737154e-13**.
- `e_model_ul/e_total` RMS ratio: **1**.
- Original / UL-sequence false-safe rate: **0.0305966133 / 0.0305966133**.
- Diagnostic-bank top-1 avg→UL / avg→plant flip: **0 / 0.0113443465**.
- Maximum identity closure error: **1.11e-16 A**.

## Interpretation

The controller average is already a duration-weighted sum of each segment Park voltage at its execution midpoint. With frozen F and alpha, segment-wise Euler increments therefore collapse algebraically to the same result; this is why `e_sequence_ul` is numerical zero.

`e_sequence_plant = i_pred_seq_plant - i_pred_avg` is a full-physics counterfactual and includes replacing the ultralocal/F model; it must not be relabelled as pure sequence averaging error. The pure input-representation check is `e_sequence_ul`.

All 14 requested figure categories are in `results/figures`.
