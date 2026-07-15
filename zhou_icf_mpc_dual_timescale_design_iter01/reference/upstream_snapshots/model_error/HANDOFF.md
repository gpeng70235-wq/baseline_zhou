# HANDOFF — 完整工程交接

生成时间：`2026-07-15 15:21:57 +08:00`  
新工程：`C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_model_error_decomposition_iter01`

## 1. 目标与边界

本工程定量判断 Zhou ICF-MPC 移植到 IPMSM 后的独立电流约束误判，主要来自 F 估计、alpha 设置、两拍冻结/显式 Euler，还是剩余一阶模型结构。所有替换都发生在闭环之后的离线重放中。禁止修改控制器、重扫 608 个 Jd/Jq 点、重做 E1/E2、重做多矢量顺序研究，或实现 ESO/RLS/辨识器/高阶控制器。

## 2. 前序研究链

| Upstream | Absolute path | Evidence | hashed files | copied files |
|---|---|---|---:|---:|
| ipmsm_probe | `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_probe_iter01` | FINAL_IPMSM_PROBE_REPORT.md;src/+zhou_ipmsm/+controller/icf_mpc_step.m | 132 | 2 |
| s2_feasibility | `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_feasibility_control_iter01` | FINAL_FEASIBILITY_CONTROL_REPORT.md;src/+zhou_feasibility/rectangle_hexagon_intersection.m | 182 | 5 |
| robust_residual | `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_robust_constraint_iter01` | FINAL_ROBUST_CONSTRAINT_REPORT.md;RESIDUAL_ALIGNMENT_AUDIT.md | 216 | 10 |
| sequence_decomposition | `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_sequence_decomposition_iter01` | HANDOFF.md;docs/SEQUENCE_DECOMPOSITION_REPORT.md;results/raw/sample_decomposition.csv | 246 | 134 |
| jd_jq_audit | `C:\Users\catkin\Documents\baseline_zhou\baseline_zhou-main\baseline_zhou-main\zhou_icf_mpc_constraint_audit_v1` | results/summary/all_constraint_cases.csv;src/+zhou_constraint/run_baseline_gate.m | 1438 | 3 |

前序已证明：平均电压与冻结 F 的逐段超局部预测差异占总残差约 `1.02737154281e-13`，仅浮点量级；plant oracle 的模型项残差为 `0 A`；原平均预测 false-safe 为 `3.059661%`；平均预测到 plant oracle 的 top-1/模式翻转分别为 `1.134435%` / `0.939842%`。因此 sequence 路线已经停止，本工程不重复它。

## 3. 环境与入口

- MATLAB：`MATLAB 24.2.0.2712019 (R2024b) (2024b)`。
- 依赖：MATLAB 基础运行时及当前工程 `src` 中逐字节复制的最小 Zhou/IPMSM/S2 runtime；不把任何兄弟工程加入路径。
- 主入口：`run_model_error_decomposition.m`。
- 一键命令：`cd('C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_model_error_decomposition_iter01'); run_model_error_decomposition();`
- 随机种子：`20260715`；控制周期 `0.0001 s`；plant 重放步长 `2e-06 s`。

## 4. P0--P5 定义与证据等级

| 预测器 | F | alpha | 离散/对象 | 分类 |
|---|---|---|---|---|
| P0 | 原 5 区间 algebraic Fhat，跨两拍冻结 | 原 alpha_d/q | 两拍 Euler、等效 pending/selected 电压 | 实际闭环基线 |
| P1 | 同 P0 Fhat | 1/Ld_actual, 1/Lq_actual | 同 P0 | oracle-alpha 离线干预 |
| P2a | 上一完整周期平均 F，original-alpha gauge | 原 alpha | 两拍冻结 F | 时间因果 oracle |
| P2b | k 时刻 IPMSM 物理漂移 F | 原 alpha | 两拍冻结 F | 当前物理 oracle |
| P2c | 用 i(k+1) 反算当前 pending 周期平均 F，original-alpha gauge | 原 alpha | 两拍冻结 F | **非因果上界** |
| P3a | 上一周期平均 F，按 oracle-alpha gauge 重算 | oracle alpha | 两拍冻结 F | 时间因果联合 oracle |
| P3b | k 时刻 IPMSM 物理漂移 F | oracle alpha | 两拍冻结 F | 当前物理联合 oracle |
| P3c | 当前 pending 周期平均 F，按 oracle-alpha gauge 重算 | oracle alpha | 两拍冻结 F | **非因果联合上界** |
| P4 | k 物理 F；第一拍预测后在 i1 重新计算 F | oracle alpha | 每拍显式 Euler | 刷新局部物理模型 |
| P5 | plant 方程隐含的连续漂移 | actual plant | 逐段命令、同对象 RK4 | 离线对象重放下界 |

时间因果并不等于可部署：P2a/P3a 要访问上一周期真实对象端点，P2b/P3b/P4 要知道真实参数，P1 也使用 oracle alpha。P2c/P3c 明确非因果，P5 是完全离线对象重放。任何 oracle 都没有反馈到闭环。

## 5. 实际运行数据

实际完成 `24` 个注册工况、`24153` 个样本；不是预计值，也不是从旧 CSV 复制的计数。工况含 9 个 core、5 个 dynamic、8 个 parameter、2 个 boundary/stress 条目；精确计数以表格为准。

| Case | Category | Range | rpm | id* | iq* | Vdc | samples | S2 | P0 FS | P5 max gap (A) | Notes |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| C01_nominal_100rpm_10A | core | normal | 100 | 0 | 10 | 48 | 1198 | 0 | 0.250417% | 0 |  |
| C02_light_100rpm_4A | core | normal | 100 | 0 | 4 | 48 | 1198 | 0 | 0.083472% | 0 |  |
| C03_light_200rpm_6A | core | normal | 200 | 0 | 6 | 48 | 1198 | 0 | 0.500835% | 0 |  |
| C04_high_200rpm_18A | core | normal | 200 | 0 | 18 | 48 | 1198 | 0 | 1.168614% | 0 |  |
| C05_negative_id | core | reasonable_extension | 300 | -4 | 15 | 48 | 1198 | 0 | 1.085142% | 0 |  |
| C06_low_bus_43p2V | core | reasonable_extension | 300 | 0 | 15 | 43.2 | 1198 | 0 | 1.836394% | 0 |  |
| C07_known_false_safe | core | normal | 500 | 0 | 20 | 48 | 29 | 7 | 65.517241% | 0 | pre-termination dynamic evidence only; excluded from steady spectrum |
| C08_S2_nontrigger | core | normal | 100 | 0 | 10 | 48 | 1198 | 0 | 0.333890% | 0 |  |
| C09_S2_boundary | core | normal | 500 | 0 | 20 | 48 | 1198 | 1 | 2.337229% | 0 |  |
| D01_iq_step | dynamic | normal | 300 | 0 | 18 | 48 | 451 | 0 | 3.325942% | 0 | pre-termination dynamic evidence only; excluded from steady spectrum |
| D02_id_step | dynamic | reasonable_extension | 300 | -5 | 0 | 48 | 1198 | 0 | 1.752922% | 0 |  |
| D03_id_iq_step | dynamic | reasonable_extension | 300 | -4 | 16 | 48 | 1198 | 0 | 2.671119% | 0 |  |
| D04_torque_ramp | dynamic | normal | 400 | 0 | 18 | 48 | 1198 | 0 | 3.923205% | 0 | ; torque reference is mapped from dq current, not an independent mechanical outer loop |
| D05_torque_step | dynamic | normal | 400 | 0 | 18 | 48 | 457 | 0 | 6.564551% | 0 | pre-termination dynamic evidence only; excluded from steady spectrum; torque reference is mapped from dq current, not an independent mechanical outer loop |
| P01_Ld_minus10 | parameter | reasonable_extension | 300 | 0 | 18 | 48 | 1198 | 0 | 5.425710% | 0 |  |
| P02_Ld_plus10 | parameter | reasonable_extension | 300 | 0 | 18 | 48 | 1198 | 0 | 0.918197% | 0 |  |
| P03_Lq_minus10 | parameter | reasonable_extension | 300 | 0 | 18 | 48 | 1198 | 0 | 6.761269% | 0 |  |
| P04_Lq_plus10 | parameter | reasonable_extension | 300 | 0 | 18 | 48 | 1198 | 0 | 2.671119% | 0 |  |
| P05_cross_mismatch | parameter | reasonable_extension | 400 | 0 | 18 | 48 | 1198 | 0 | 6.260434% | 0 |  |
| P06_controller_high_L | parameter | reasonable_extension | 400 | 0 | 18 | 48 | 1198 | 0 | 7.595993% | 0 |  |
| P07_controller_low_L | parameter | reasonable_extension | 400 | 0 | 18 | 48 | 1198 | 0 | 1.669449% | 0 |  |
| P08_opposed_20pct | parameter | reasonable_extension | 400 | -3 | 17 | 48 | 1198 | 0 | 7.345576% | 0 |  |
| B01_500rpm_20A_48V_fast | boundary | stress_test | 500 | 0 | 20 | 48 | 3 | 2 | 0.000000% | 0 | pre-termination dynamic evidence only; excluded from steady spectrum |
| B02_500rpm_negid_48V | boundary | stress_test | 500 | -4 | 19.5959179423 | 48 | 451 | 0 | 4.656319% | 0 | pre-termination dynamic evidence only; excluded from steady spectrum |

## 6. 主要结果

口径：**REPRODUCTION_ALL**

| Predictor | Causality | valid n | vector RMS (A) | peak (A) | false-safe | false-alarm | max FS run | top-1 flip vs P0 | mode flip vs P0 |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| P0 | causal_original | 24153 | 0.0462765806219 | 0.57171231501 | 3.059661% | 0.000000% | 11 | 0.000000% | 0.000000% |
| P1 | causal_original | 24153 | 0.313096475601 | 1.07672867773 | 1.999752% | 16.585931% | 11 | 9.410839% | 5.779820% |
| P2a | causal_previous_period_oracle | 24129 | 0.0639743506626 | 0.527630896212 | 1.877409% | 1.504414% | 11 | 1.498779% | 0.770091% |
| P2b | offline_physical_parameter_oracle | 24153 | 0.31213763231 | 0.932835107894 | 1.055769% | 17.335321% | 10 | 14.375026% | 6.425703% |
| P2c | noncausal_future_endpoint_oracle | 24153 | 0.0451051288638 | 0.288581654687 | 1.622987% | 1.316607% | 10 | 1.606426% | 1.304186% |
| P3a | causal_previous_period_oracle | 24129 | 0.0193138460033 | 0.269943850411 | 0.915910% | 0.327407% | 11 | 0.997806% | 0.948122% |
| P3b | offline_physical_parameter_oracle | 24153 | 0.0193622378884 | 0.193922473834 | 0.807353% | 0.794932% | 10 | 1.018507% | 0.948122% |
| P3c | noncausal_future_endpoint_oracle | 24153 | 0.00745979125119 | 0.0949396561515 | 0.679005% | 0.298100% | 10 | 1.088892% | 0.919140% |
| P4 | offline_physical_parameter_oracle | 24153 | 0.00744528837188 | 0.0942986359173 | 0.679005% | 0.298100% | 10 | 1.088892% | 0.919140% |
| P5 | offline_plant_replay_oracle | 24153 | 0 | 0 | 0.000000% | 0.000000% | 0 | 1.134435% | 0.939842% |

门禁主域 `ENGINEERING_PRIMARY` 排除明确 stress test。该主域的 F/alpha/结构有符号解释份额分别为 `53.877574%`、`28.662760%`、`17.459667%`；P0→P2b、P0→P1、P0→P3b 的 false-safe 绝对变化分别为 `+1.995865 percentage points`、`+1.080214 percentage points`、`+2.249040 percentage points`。

候选诊断的 F、alpha、结构 top-1 恢复率分别为 `47.058824%`、`30.514706%`、`89.338235%`；它们只用于确认误差是否可能跨越决策边界，不是主要归因证据。

## 7. 正式结论与下一路线

**C — F and alpha jointly dominate**。推荐：separate compute-bounded extended-affine ultralocal study; independently audit the stable 6x/12x electrical-periodic residual before considering any resonator。当前工程到此停止，不实现建议算法。

## 8. 核心产物

- 逐样本：`C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_model_error_decomposition_iter01\results\raw\model_error_samples.csv`
- 汇总：`C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_model_error_decomposition_iter01\results\summary`（8 个注册 CSV，另含 `final_decision.csv` 和审计表）。
- 图片：`C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_model_error_decomposition_iter01\results\figures`，已生成 `15/15`。
- 正式报告：`C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_model_error_decomposition_iter01\docs\MODEL_ERROR_DECOMPOSITION_REPORT.md`
- 重现说明：`C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_model_error_decomposition_iter01\RUN_AND_REPRODUCE.md`

## 9. SHA256 与隔离

文档生成时逐文件比较状态为 **PASS**：BEFORE `2214` 个文件，AFTER `2214` 个文件，变化 `0`。`all` 流程随后由 `finalize_freeze` 再次断言并写入 `FROZEN_UPSTREAM_VALIDATION.csv`。复制来源共 `154` 个最小依赖/证据文件，逐字节一致失败数 `0`。

## 10. 如何增加工况

只在当前工程的本地 `config/sequence_scenarios.m` 增加一个具名、分类、带 `range_class` 的行；不要改上游。换过工况集合后必须更新注册样本计数或 audit version、清除对应本地 MAT cache、重新运行 `all`，并同时检查 baseline、P0/P5 对齐、频谱相干窗、决定门禁和 SHA256。压力点必须继续独立标记，不能主导工程结论。

## 11. 未完成事项与禁止项

未完成事项仅是结论所指向的下一独立项目；本工程的 P0--P5、汇总、15 类图和 A--F 决策已经完成。严禁修改五个冻结上游、将 P2c/P3c/P5 称为可部署控制器、把相关性当因果、把诊断候选 ranking 当原生控制器结果、无条件收紧 Jd/Jq，或在本目录加入新控制算法。

主域 P0 false-safe：**3.029664%**；全量 P0 false-safe：**3.059661%**。所有最终数字应从 CSV 重读，不从本文手工转录。
