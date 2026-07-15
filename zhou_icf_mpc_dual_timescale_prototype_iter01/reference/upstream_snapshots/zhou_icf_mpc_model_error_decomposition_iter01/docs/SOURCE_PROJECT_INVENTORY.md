# Source Project Inventory

## 冻结上游

| Upstream | Absolute path | Evidence | hashed files | copied files |
|---|---|---|---:|---:|
| ipmsm_probe | `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_probe_iter01` | FINAL_IPMSM_PROBE_REPORT.md;src/+zhou_ipmsm/+controller/icf_mpc_step.m | 132 | 2 |
| s2_feasibility | `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_feasibility_control_iter01` | FINAL_FEASIBILITY_CONTROL_REPORT.md;src/+zhou_feasibility/rectangle_hexagon_intersection.m | 182 | 5 |
| robust_residual | `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_robust_constraint_iter01` | FINAL_ROBUST_CONSTRAINT_REPORT.md;RESIDUAL_ALIGNMENT_AUDIT.md | 216 | 10 |
| sequence_decomposition | `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_sequence_decomposition_iter01` | HANDOFF.md;docs/SEQUENCE_DECOMPOSITION_REPORT.md;results/raw/sample_decomposition.csv | 246 | 134 |
| jd_jq_audit | `C:\Users\catkin\Documents\baseline_zhou\baseline_zhou-main\baseline_zhou-main\zhou_icf_mpc_constraint_audit_v1` | results/summary/all_constraint_cases.csv;src/+zhou_constraint/run_baseline_gate.m | 1438 | 3 |

## SHA256 状态

- BEFORE 文件：`2214`。
- AFTER 文件：`2214`。
- 新增/删除/修改总数：`0`。
- 文档生成时判断：**PASS**。
- 比较说明：Documentation-time BEFORE/AFTER key and SHA256 comparison found zero added, deleted, or modified upstream files.

`all` 模式在文档之后仍执行 `finalize_freeze` 强断言，并生成 `SOURCE_SHA256_AFTER.csv` 和 `FROZEN_UPSTREAM_VALIDATION.csv`。任何非零变化都会使运行失败。

## 最小复制闭包

COPIED_FILE_PROVENANCE 共 `154` 行，逐字节一致失败 `0`。运行代码仅包含本项目需要的 `+zhou_ipmsm`、`+zhou_feasibility`、`+zhou_iter11_ref`、一个 robust case runner、sequence 参考分解器、配置及冻结报告快照。复制文件的原路径、相对路径、大小、时间、SHA256、目标路径和用途均在根目录 CSV 中。

## 路径原则

所有 MATLAB 查询必须解析到 `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_model_error_decomposition_iter01` 内。上游绝对路径只用于只读 inventory/hash；运行时不 `addpath` 上游。详见 `PATH_CONFLICT_REPORT.md` 与 `audit/path_resolution.csv`。
