# HANDOFF — Zhou ICF-MPC IPMSM 序列/模型误差分解

本文件记录 2026-07-15 已完成的正式运行、冻结证据与交接边界。

## 1. 项目目标

在不改变原闭环输出的条件下，将 `i_actual(k+2)-i_pred_avg(k+2|k)` 分解为多矢量序列表示相关项与模型/F 估计相关项，并判断二者是否导致独立 d/q 电流约束 false-safe、false-alarm 或离线诊断候选决策变化。

## 2. 此前已完成的旧工程

- IPMSM 基础移植与退化/负 id/独立 alpha 验证。
- S2 矩形–六边形显式电压可行性修正及 500 rpm、20 A、48 V 边界回归。
- k+2 总残差、Calibration/Validation/Test 划分与 E1/E2 经验边界失败审计。
- 608 点 Jd–Jq 扫描和迁移审计。
- 相关兄弟工程还做过平均输入与逐段序列的物理根因探查，但没有完成本项目的 IPMSM 闭环三层分解。

详见 `docs/PREVIOUS_WORK_INVENTORY.md`。

## 3. 为何不是重复工作

稳健残差工程保存了原平均预测、实际 k+2、电流总残差和 selected/applied 序列，但没有同时生成 `i_pred_seq_ul`、`i_pred_seq_plant`、`e_sequence`、`e_model` 以及三模型离线候选重评。相关 A2 工程也没有给出本 IPMSM/S2 闭环的完整三层分解。因此防重复门结论为“允许继续”，见 `docs/DUPLICATE_WORK_CHECK.md`。

## 4. 四个冻结上游路径

1. `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_probe_iter01`
2. `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_feasibility_control_iter01`
3. `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_robust_constraint_iter01`
4. `C:\Users\catkin\Documents\baseline_zhou\baseline_zhou-main\baseline_zhou-main\zhou_icf_mpc_constraint_audit_v1`

## 5. 新项目目录

`C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_sequence_decomposition_iter01`

## 6. MATLAB 版本

MATLAB R2024b。若在其他版本复现，必须记录版本差异，重新执行基线、重复性及路径门，不能与正式运行宣称逐字节等价。

## 7. 主入口

`run_sequence_decomposition.m`

## 8. 一键运行命令

```matlab
cd('C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_sequence_decomposition_iter01')
run_sequence_decomposition('all')
```

## 9. 三层预测定义

- 平均层：原控制器 `i_pred_avg(k+2|k)`，不改 F、alpha、Euler 式或等效电压。
- ultralocal-sequence 层：冻结 `Fd/Fq` 与 `alpha_d/alpha_q`，对 pending 和 selected 的最终多矢量命令做两周期逐段 Euler。
- plant-model-sequence 层：从实际 `x(k)` 出发，以实际 IPMSM 参数和演化角度对同一两周期最终序列逐段积分。
- 实际层：闭环轨迹 `i_actual(k+2)`，不由离线重放替代。

由于冻结超局部模型对电压是仿射的，逐段 Euler 与使用各段中点角形成的等效平均电压在代数上相同。UL 层出现超出浮点容差的差异时，应先判为时序、角度、命令或实现错误，而不是控制现象。

## 10. 残差分解

```text
e_total          = i_actual        - i_pred_avg
e_sequence_ul    = i_pred_seq_ul   - i_pred_avg
e_model_ul       = i_actual        - i_pred_seq_ul
e_sequence_plant = i_pred_seq_plant- i_pred_avg
e_model_plant    = i_actual        - i_pred_seq_plant
```

两套恒等式 `e_total = e_sequence + e_model` 必须逐轴逐样本闭合。时间对齐固定为 `selected(k) -> applied(k+1) -> actual(k+2)`。

## 11. 已运行工况

- 正式运行状态：24/24 个预注册工况均实际启动并保留数据；19 个完成 0.12 s 全时域，5 个按冻结非法命令语义提前终止。
- 已运行类别：core / dynamic / parameter / boundary = **9 / 5 / 8 / 2**。
- 完成全时域类别：core / dynamic / parameter / boundary = **8 / 3 / 8 / 0**。
- 提前终止：`C07_known_false_safe`、`D01_iq_step`、`D05_torque_step`、`B01_500rpm_20A_48V_fast`、`B02_500rpm_negid_48V`；失败前数据未补值、未删除。
- normal / reasonable_extension / stress_test 的已运行数 = **10 / 12 / 2**。
- 总有效严格 k+2 对齐样本数：**24,153**。

## 12. 关键 CSV 和图片

- 逐样本：`results/raw/sample_decomposition.csv` — **24,153 行正式数据**。
- 工况指标：`results/summary/case_metrics.csv`。
- 分解：`results/summary/residual_decomposition.csv`。
- 约束混淆矩阵：`results/summary/constraint_confusion_matrix.csv`。
- 序列模式：`results/summary/sequence_pattern_statistics.csv` 与 `sequence_mode_residual_summary.csv`。
- 离线候选：`results/summary/candidate_decision_comparison.csv`；逐样本三方法详情在 `results/raw/candidate_revaluation_detail.csv`。
- 重复性：`results/summary/repeatability_check.csv`，三次关键字段最大差为 0。
- 图片目录：`results/figures`，要求的 **14/14** 类均已生成。

原控制器没有原生有限候选或 top-3；候选 CSV 只描述离线诊断候选库，不反馈闭环。

## 13. A–E 最终结论

**B — 一阶超局部模型或 F 估计误差为主要来源。**

- `e_sequence_ul/e_total` RMS 比：`1.0273715428e-13`。
- `e_model_ul/e_total` RMS 比：`1.0000000000`。
- 原平均预测 / UL 逐段预测 false-safe：`3.05966133% / 3.05966133%`。
- 离线诊断候选库 avg→UL top-1 翻转：`0%`；avg→plant top-1 翻转：`1.13443465%`。
- 两套恒等式最大闭合误差：`1.1102230246e-16 A`。

详见 `docs/SEQUENCE_DECOMPOSITION_REPORT.md` 与 `docs/DECISION_AND_NEXT_STEP.md`。

## 14. 是否允许 prototype

**DENY**。结论为 B，逐段 UL 不降低 false-safe，avg→UL 候选 top-1 不翻转；六项门仅 3/6。未建立或执行任何控制器原型，详见 `docs/PROTOTYPE_GATE_REPORT.md`。

## 15. 未完成工作

- 5 个快速动态/边界工况按冻结非法命令语义提前终止；它们是对象/S2-S3 适用边界，不能用来宣称完整 0.12 s 性能。
- 本项目未把 `e_model_ul` 继续唯一分解为 F 估计、模型阶次、参数和未建模扰动；这属于下一独立工程。
- 没有台架、DSP/FPGA、死区/噪声或闭环转速环验证；plant oracle 不能部署。

## 16. 下一路线

建立新的独立工程研究“扩展仿射超局部映射或 F 估计改进”，保持原 Jd/Jq 与 S2 层，不复活 E1/E2，不在本工程实现序列预测原型。

## 17. SHA256 结果

- before 清单：`SOURCE_SHA256_BEFORE.csv`
- after 清单：`SOURCE_SHA256_AFTER.csv`，共 **1,968** 个冻结文件。
- 上游变化文件数：**0**；144 个复制文件复核失败数：**0**。

## 18. 如何增加新工况

在 `config/sequence_scenarios.m` 增加唯一 case_id、类别、范围等级和明确诊断假设。只允许为区分误差来源增加定向工况，不构造新的广泛笛卡尔积；参数偏差达到或超过 ±30% 必须标为压力测试。保留既有失败轨迹并使用新 run_id。

## 19. 如何复现

按 `RUN_AND_REPRODUCE.md` 从新 MATLAB 会话运行 `all`，先通过路径和最小基线门，再审计三层预测、恒等闭合、离线候选和重复性，最后复核 after SHA。不要手工把兄弟工程加入路径。

## 20. 禁止修改内容

禁止修改四个冻结上游、复制来的原控制器/IPMSM/S2 源码、`Jd_limit=Jq_limit=0.16 A^2`、selected/pending/applied 延迟语义及正式原始结果。禁止重跑 608 点扫描、重建 E1/E2、加入 ESO/RLS/全模型在线估计/神经网络，或把离线 plant oracle/诊断候选库包装成已部署算法。
