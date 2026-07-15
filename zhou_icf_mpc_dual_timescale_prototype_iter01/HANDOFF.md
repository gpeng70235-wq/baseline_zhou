# Handoff

1. Goal: implement the frozen S2-aware dual-timescale predictor in the Zhou IPMSM closed loop.
2. Research chain: constraint/probe/feasibility/robust → sequence → model-error → design → this prototype.
3. Design conclusion was permission to prototype, not proof of performance.
4. Project: `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_dual_timescale_prototype_iter01`.
5. Executable source: Git commit `2aa4e7fe2987184b36f4ffca0e9d0cabcfb7e7ff`, restored under `reference/upstream_snapshots`.
6. Frozen upstreams: seven paths in `audit/SOURCE_PROJECTS.csv`; five are empty stubs.
7. Methods: B0 original; B1 slow alpha only; B2 slow alpha+fast F; P adds decision trend; RLS is a constrained comparator.
8. P formula and parameters are in `config/FROZEN_PROTOTYPE_PARAMETERS.m`.
9. Timing: pending(k) executes k→k+1; selected_final(k) executes k+1→k+2; both predictions use one Ts.
10. Applied voltage is reconstructed from final post-S2 vector IDs/durations, Vdc and segment-midpoint Park angles.
11. Gates: excitation, S2 input quality, and next-row latched decision margin.
12. Calibration used only C01, P08 and D03 and retained the corrected design default.
13. Frozen parameter SHA is in `audit/PARAMETER_FREEZE_SHA256.txt`.
14. Minimal result: FAIL; see `results/summary/minimal_case_metrics.csv`.
15. Full 24-method campaign: NOT RUN by hard-gate rule.
16. ENGINEERING_PRIMARY method metrics in `method_metrics.csv` are explicitly MINIMAL_GATE_ONLY.
17. Ablation: NOT RUN.
18. Sensitivity: NOT RUN.
19. Final timing/DSP audit: NOT RUN; no hardware timing claim.
20. Final conclusion: C.
21. Final algorithm formed: no.
22. Retained modules: none were frozen as a final algorithm.
23. Deleted modules: none; the route stopped before a valid ablation decision.
24. CSVs are under `results/summary`; five gate figures are under `results/figures/minimal`.
25. One-command reproduction is documented in `RUN_AND_REPRODUCE.md`.
26. Upstream after/before result is `audit/FROZEN_UPSTREAM_VALIDATION.csv` and must remain zero-change.
27. Known limitations are in `docs/KNOWN_LIMITATIONS.md`.
28. HIL/hardware validation remains necessary for any future algorithm, but this iter01 is not a hardware candidate.

Key numbers: B0/P false-safe 3.526239% / 3.753128%; B0/P vector RMS 0.0613189 / 0.132352 A.
