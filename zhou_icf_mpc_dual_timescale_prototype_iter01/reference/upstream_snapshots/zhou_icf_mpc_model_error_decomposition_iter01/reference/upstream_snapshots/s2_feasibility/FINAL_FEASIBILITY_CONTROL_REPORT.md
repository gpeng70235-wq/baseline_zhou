# Zhou ICF-MPC IPMSM Explicit Voltage-Feasibility Control

## Executive result

Decision: **A. S2保持原独立约束并消除非法命令，跨工况无工程量级恶化**. Proposed completes the frozen 500 rpm/20 A/48 V/5 ms case with zero illegal commands and zero negative dwell.

## Frozen regression

Formal P0 100/300/500 rpm independent closed loops pass pointwise. P1 retains selected illegal at 4.4 ms and applied illegal at 4.5 ms with the frozen reference and duties.

## Set audit

The original illegal sample has R∩H area `21.4170793 V^2`; S2-preservable ratio is `100.00%`. S2 offset `1.44717522 V` is smaller than radial `1.48261496 V`, and both happen to remain in R for this sample.

## A1 original failure

S0 is FAIL and has no steady THD/torque metrics. S1 and proposed both finish 0.2 s. Proposed fallback ratio is `0`, predicted d/q satisfaction is `[1, 1]`, actual engineering violation rates are `[0.0215, 0.0255]`. Its steady THD is `0.939449999%`, torque ripple `0.0429320043 Nm`, switching actions `7316`; average/p95/max host execution times are `[0.000339306167, 0.00073603, 0.0015347] s`.

## A2 paired six-condition matrix

Proposed passes `12/12`; S1 passes `12/12`; S0 passes `11/12`. Across all S0-feasible paired rows, proposed returns the original command and maximum engineering relative change is `0`.

The feasibility layer accounts for mean/max `[0.0481645054, 0.0736556232]` of proposed A2 host execution time, below the preregistered 10% engineering-change threshold.

## A3 boundary revalidation

Proposed passes `24/24` points and modifies zero commands in every original-feasible point. The original FAIL rows are retained explicitly.

## A4 negative-id admission

Proposed passes `12/12` probes with aggregate fallback fraction `0`; S0 passes `10/12`. This is an admission probe only and does not introduce MTPA.

## S3 status

No registered main or admission operating point required S3; its correctness is established by synthetic empty-intersection tests and independent dense edge enumeration, not by claiming an observed fallback benefit.

## Timing scope

Execution times are MATLAB host measurements after excluding the first 10% of cycles. They are comparative evidence, not an embedded real-time certification.

## Boundaries

No Vdc/ramp change is presented as the algorithm, and no F, alpha, J, motor, MTPA, duty clipping or silent sample deletion is used.
