# Experiment Protocol

## 注册设计

闭环对每个场景只运行原 Zhou+S2 控制器；随后在相同 state(k)、pending(k)、selected(k)、ref(k) 上离线计算十个预测器。仿真时长 `0.12 s`，steady 起点 `0.06 s`，控制周期 `0.0001 s`，对象重放子步 `2e-06 s`。

## 实际场景

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

共 `24` 个场景、`24153` 个 k→k+2 样本。提前触发保护的轨迹保留其有效动态样本并标记 truncated；stress test 不进入 A--F 主域。

## 替换与比较

在全部样本上计算 residual/J/confusion；涉及 P2a/P3a 的 MSE 分解使用所有预测器均有限的公共交集。F 收益比较 P0→P2a/P2b，alpha 收益比较 P0→P1，联合比较 P0→P3a/P3b，冻结/离散链比较 P3b→P4→P5。P2c/P3c 只报告上界，不参与主要结论门禁和有效候选 ranking。

## 候选诊断

每个样本的 bank 含闭环 final selected、pre-S2 core、V0、六个满幅有功矢量和六个扇区三矢量中心，按命令 signature 去重。十个预测器在同一 bank 上按归一化 Jd+Jq 稳定排序。这个 bank 不是原 Zhou 连续矩形--六边形几何搜索，因此 top-1/top-3/mode 只回答“预测误差能否改变一个固定诊断选择”，不作为 A--F 主证据。P2c/P3c ranking 标为 invalid。P5 10-us 候选积分用抽样的 2-us 重排一致性检查。

## 频谱

只用 steady、定速、参考变化率近零且至少 3 个完整电气周期的尾部相干窗；矩形窗恰好包含整数周期，检查 1x/6x/12x 并记录前三主峰。无法形成整数周期或基波过小的行标 invalid，不用补零或泄漏窗口强行解释。

## 重复性

| Check | Pass | Observation | Requirement |
|---|---:|---|---|
| baseline_three_run_numeric | PASS | max_numeric_delta=0 | <=1e-12 |
| P0_formula_reproduction | PASS | max_gap_A=0 | <=2e-10 A |
| P5_exact_replay | PASS | max_gap_A=0 | <=2e-9 A |
| selected_applied_command_carry | PASS | all_pass=1 | all true |
| candidate_P5_step_convergence | PASS | failures=0 checks=472 | zero ranking flips |
| random_seed_frozen | PASS | seed=20260715 | fixed deterministic seed |

所有替换均为离线分析；没有任何 P1--P5 输出改变原轨迹、S2 触发或最终电压。
