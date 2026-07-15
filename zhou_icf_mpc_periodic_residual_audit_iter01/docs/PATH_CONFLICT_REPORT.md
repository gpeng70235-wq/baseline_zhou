# Path Conflict Report

顶层路径中以下项目为空 stub 或缺失，未被当作完整源码：`model_error`, `s2_feasibility`, `sequence_decomposition`, `jd_jq_audit`。
model-error 完整快照从 dual-timescale prototype 的 Git 冻结副本解析；feasibility、sequence、Jd/Jq 则从该完整快照内的 evidence/runtime 解析。
`audit/SOURCE_PROJECTS.csv` 保存 requested_path、resolved_path 和选择理由。新工程未把任何 sibling 目录加入 MATLAB path。
新工程绝对路径：`C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_periodic_residual_audit_iter01`；分支：`codex/zhou-periodic-residual-audit-iter01`。
