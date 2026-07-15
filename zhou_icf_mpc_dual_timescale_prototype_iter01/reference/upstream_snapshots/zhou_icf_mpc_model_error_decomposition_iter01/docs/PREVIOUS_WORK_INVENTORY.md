# Previous Work Inventory

本表盘点的是冻结证据，不把旧结果冒充本工程新实验。五个上游均保持只读。

| Upstream | Absolute path | Evidence | hashed files | copied files |
|---|---|---|---:|---:|
| ipmsm_probe | `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_probe_iter01` | FINAL_IPMSM_PROBE_REPORT.md;src/+zhou_ipmsm/+controller/icf_mpc_step.m | 132 | 2 |
| s2_feasibility | `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_feasibility_control_iter01` | FINAL_FEASIBILITY_CONTROL_REPORT.md;src/+zhou_feasibility/rectangle_hexagon_intersection.m | 182 | 5 |
| robust_residual | `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_robust_constraint_iter01` | FINAL_ROBUST_CONSTRAINT_REPORT.md;RESIDUAL_ALIGNMENT_AUDIT.md | 216 | 10 |
| sequence_decomposition | `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_sequence_decomposition_iter01` | HANDOFF.md;docs/SEQUENCE_DECOMPOSITION_REPORT.md;results/raw/sample_decomposition.csv | 246 | 134 |
| jd_jq_audit | `C:\Users\catkin\Documents\baseline_zhou\baseline_zhou-main\baseline_zhou-main\zhou_icf_mpc_constraint_audit_v1` | results/summary/all_constraint_cases.csv;src/+zhou_constraint/run_baseline_gate.m | 1438 | 3 |

## 已经建立的先验

1. IPMSM 基础工程给出可运行 Zhou 控制器、对象、指标和已接受基线。
2. S2 工程已经完成矩形--六边形求交、S2 触发和非法作用时间门禁，本工程只复用最终命令。
3. robust residual 工程已经定义 k→k+2 残差对齐、场景分组和历史残差数据；本工程不重复 E1/E2 边界。
4. sequence decomposition 已经证明冻结同一 F/alpha 时，平均电压预测与逐段等效电压预测的差异仅为浮点量级；sequence/total 比为 `1.02737154281e-13`，model/total 比为 `1`。
5. sequence decomposition 的 plant oracle 模型残差为 `0 A`，原预测 false-safe `3.059661%`，平均→plant top-1/模式翻转 `1.134435%` / `0.939842%`。
6. Jd/Jq audit 的 608 点扫描已经完成；本工程不再次运行。

## 可直接复用

场景定义、控制器/plant/S2 最小 runtime、时间对齐约定、候选诊断 bank 语义、上游报告和既有 sequence baseline 可直接作为冻结输入或门禁证据。

## 必须重新仿真的字段

P0--P5 的逐样本预测、匹配 alpha gauge 的上一周期/当前周期 F oracle、P4 刷新斜率、P5 两段对象重放、每个预测器的 Jd/Jq/confusion、候选重排序、相关性和频谱均须由本工程本地轨迹产生。本次实际生成 `24153` 行，而非从 sequence CSV 拼接。

## 为什么不重复 sequence 工程

sequence 工程回答的是“多矢量执行顺序/平均化是否造成误差”；答案是否定的。当前工程回答的是在该等价性成立后，`F+alpha*u` 内部哪一部分以及 Euler/冻结假设造成对象差异。研究问题、预测器阶梯、输出字段和 A--F 门禁均不同。
