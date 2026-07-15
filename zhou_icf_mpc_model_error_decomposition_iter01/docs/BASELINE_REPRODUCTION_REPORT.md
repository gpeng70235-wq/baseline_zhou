# Baseline Reproduction Report

Result: **10/10 checks passed**. Fixed independent limits are `Jd_limit = Jq_limit = 0.16 A^2`.

| Check | Pass | Observation | Requirement |
|---|---:|---|---|
| accepted_IPMSM_nominal | 1 | completed=1 illegal=0 | complete and legal |
| Ld_equals_Lq_degeneration | 1 | Ld=0.001 Lq=0.001 | P0 complete with Ld=Lq |
| negative_id_case | 1 | id_ref=-4 completed=1 | negative-id complete |
| independent_alpha_d_q | 1 | alpha_d=1250 alpha_q=833.333333333 | axis-specific and unequal |
| S2_nontrigger | 1 | S2_cycles=0 | zero S2 cycles |
| S2_boundary_trigger | 1 | S2_cycles=1 | >0 S2 cycles |
| representative_false_safe | 1 | aligned_joint_false_safe_rate=0.793103448276 | >0 in frozen representative |
| sequence_term_floating_point | 1 | max_sequence_gap_A=3.7059670289162387e-15 | <=2e-10 A |
| plant_oracle_replay | 1 | max_plant_gap_A=0 | <=2e-09 A |
| three_run_repeatability | 1 | max_numeric_delta=0 | <=1e-12 |

The local frozen runtime was executed for nominal IPMSM, Ld=Lq degeneration, negative-id, S2 non-trigger, S2 boundary, and known false-safe cases. The nominal case was executed three times.

Strict two-period alignment gave maximum average-vs-piecewise-UL gap `3.7059670289162387e-15 A`, plant replay gap `0 A`, and three-run numeric delta `0`. No result was taken from the 608-point Jd/Jq scan.
