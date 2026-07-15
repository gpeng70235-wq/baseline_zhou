# MATLAB Path Conflict Report

Audit time: `2026-07-15T15:19:57.489+08:00`  
Project root: `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_model_error_decomposition_iter01`

Result: **PASS**. All 13 required roles resolve only inside this isolated project.

The requested generic roles `estimate_ultralocal_F`, alpha setting, action-time calculation, and candidate ranking are not standalone public function names in the frozen implementation. Their concrete implementations are respectively `estimate_F_algebraic`, controller motor `alpha_d/alpha_q`, `case1/2/3_command`, and `icf_mpc_step`; the table records these explicit mappings.

No sibling `zhou_*` project is present on the active MATLAB path. MATLAB toolbox paths remain at their restored defaults.
