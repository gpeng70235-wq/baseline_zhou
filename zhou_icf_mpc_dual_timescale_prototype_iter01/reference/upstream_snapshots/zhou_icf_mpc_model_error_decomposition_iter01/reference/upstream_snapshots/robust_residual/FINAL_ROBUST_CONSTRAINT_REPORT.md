# Zhou ICF-MPC IPMSM 预测残余边界鲁棒收紧专项最终报告

正式 run_id：20260713_122037_robust_constraint  
项目：zhou_icf_mpc_ipmsm_robust_constraint_iter01  
最终判定：**D. 残余边界不足**

## 1. 结论先行

阶段 A 已完成且失败，阶段 B 已按预注册规则停止。

E1 与 E2 都能 100% 覆盖 Calibration，但不能在独立 Test 达到每轴 99.9% 的确定性覆盖门。E1 Test d/q 覆盖率为 99.8474674%/97.9241545%，E2 为 99.8246752%/97.8645441%。两种边界也都出现多周期连续漏覆盖；E2 在 Test 上还没有比 E1 获得更小的平均 d+q 边界。

因此：

- C1_global_robust_tightening：NOT_RUN_STAGE_A_GATE_FAILED
- C2_scheduled_robust_tightening：NOT_RUN_STAGE_A_GATE_FAILED
- C3_offline_oracle_tightening：NOT_RUN_STAGE_A_GATE_FAILED

本工程没有 C1/C2/C3 的正式实际违约率、THD、转矩纹波、开关动作、S2/S3、证书率或执行时间。相关数值全部是 NaN，不以零代替。

## 2. 独立性与冻结基线

工程直接源自冻结的 zhou_icf_mpc_ipmsm_feasibility_control_iter01，但运行时不依赖三个冻结工程。

PATH_ISOLATION_AUDIT.md 证明：

- initialize_project 执行 restoredefaultpath；
- zhou_ipmsm.controller.icf_mpc_step、zhou_feasibility.apply_feasibility_layer、zhou_robust.run_robust_case 和 zhou_robust.build_residual_dataset 均解析到本工程；
- MATLAB 路径中不存在三个冻结项目、Wu 项目或历史复现项目的禁止 token。

本工程未改变 IPMSM 模型、Fhat 代数估计器、alpha_mode、原 Jd/Jq、Case 1/2、S2/S3、三矢量作用时间、selected/pending/applied 延迟或 THD/工程约束统计口径。

## 3. C0 正式回归

正式场景为 500 rpm、id_ref=0 A、iq_ref=20 A、48 V、5 ms、0.2 s。

BASELINE_COMPARISON.csv 共 111 个比较行，全部 PASS；聚合行比较 2000 个周期的全部公共控制信号，最大绝对误差为 0，精确匹配率为 1。

C0 正式指标：

| 指标 | 数值 |
|---|---:|
| 非法控制命令 | 0 |
| 负作用时间 | 0 |
| 名义 predicted d/q 满足率 | 1 / 1 |
| 实际 d/q 工程约束违约率 | 0.0215 / 0.0255 |
| 实际 d-or-q 联合违约率 | 0.0450 |
| id/iq RMSE | 0.139475513 / 0.186643696 A |
| 相电流 THD | 0.939449999% |
| 平均转矩 | 9.703619273 Nm |
| 转矩纹波 | 0.042932004 Nm |
| 开关动作 | 7316 |
| S2/S3 | 0.0005 / 0 |

实际 d/q 2.15%/2.55% 是本专项要处理的冻结问题，不是通过改变原工程口径得到的。

## 4. 残余对齐与数据隔离

残余严格定义为：

\[
e_{d,q}(k)=i_{d,q,\mathrm{actual}}(k+2)-i_{d,q,\mathrm{pred}}(k+2\mid k).
\]

对齐审计逐行检查 prediction/selected/pending/applied/actual index、序列、作用时间和电角度。末尾两个无法观测 k+2 的预测行不填充。

| 数据集 | 完整场景 | 对齐有效行 |
|---|---:|---:|
| Calibration | 17 | 33966 |
| Validation | 22 | 43956 |
| Test | 32 | 57037 |

数据在拟合前按完整场景冻结，不进行控制周期随机拆分。E1/E2 只读取 Calibration。E2 在线特征是当前绝对电角速度、绝对 id/iq、电压利用率、扇区/Case/命令切换指示和参考斜率；不含未来电流、未来 Case、未来电压、真实 plant scale 或测试集统计量。

## 5. 残余统计

| 数据集 | 轴 | signed mean (A) | RMSE (A) | MAE (A) | p95 abs (A) | max abs (A) |
|---|---|---:|---:|---:|---:|---:|
| Calibration | d | 0.004076881 | 0.027952961 | 0.013593257 | 0.037491057 | 0.315360879 |
| Calibration | q | -0.000514309 | 0.012408104 | 0.008434145 | 0.026042907 | 0.070353349 |
| Validation | d | 0.003924976 | 0.046862797 | 0.023269854 | 0.083375326 | 0.705524427 |
| Validation | q | -0.000443483 | 0.020531282 | 0.011707710 | 0.038816192 | 0.257960365 |
| Test | d | 0.006013449 | 0.043333175 | 0.019646528 | 0.068383239 | 0.618413229 |
| Test | q | -0.000548011 | 0.021769452 | 0.012106756 | 0.041233047 | 0.291325588 |

Validation/Test 极值明显超过 Calibration 极值，直接解释了 Calibration 最大值边界不能外推。关联分析只作为 association：例如 d 轴绝对残余与参考斜率的相关系数为 0.519453；不作因果宣称。

## 6. E1/E2 边界

E1 使用 Calibration 最大绝对残余：

- epsilon_d = 0.315360879184449 A
- epsilon_q = 0.0703533486797596 A

聚合覆盖率：

| 边界 | 数据集 | d | q | joint |
|---|---|---:|---:|---:|
| E1 | Calibration | 1 | 1 | 1 |
| E1 | Validation | 0.997178997 | 0.983210483 | 0.980389480 |
| E1 | Test | 0.998474674 | 0.979241545 | 0.977961674 |
| E2 | Calibration | 1 | 1 | 1 |
| E2 | Validation | 0.991627992 | 0.982687233 | 0.974952225 |
| E2 | Test | 0.998246752 | 0.978645441 | 0.977348037 |

Test 最长连续漏覆盖：

| 边界 | d | q | joint |
|---|---:|---:|---:|
| E1 | 25 | 8 | 25 |
| E2 | 4 | 8 | 8 |

平均/最大边界：

| 边界/数据集 | d mean/max (A) | q mean/max (A) |
|---|---|---|
| E1 Calibration | 0.315360879 / 0.315360879 | 0.070353349 / 0.070353349 |
| E1 Validation | 0.315360879 / 0.315360879 | 0.070353349 / 0.070353349 |
| E1 Test | 0.315360879 / 0.315360879 | 0.070353349 / 0.070353349 |
| E2 Calibration | 0.148500151 / 0.503577075 | 0.064501728 / 0.139617842 |
| E2 Validation | 0.544398477 / 1.767153891 | 0.072629568 / 0.123851246 |
| E2 Test | 0.318935718 / 4.065960619 | 0.067583710 / 1.796552793 |

E2 Test d/q 超过原 0.4 A 半宽的聚合比例为 0.141066325/0.000035065。E1 为 0/0。

## 7. 硬门审计

| 门槛 | 结果 | 证据 |
|---|---|---|
| 确定性 Test 每轴覆盖率 ≥ 0.999 | FAIL | E1/E2 d、q 均至少一轴低于门槛 |
| 严重连续漏覆盖 ≤ 1 周期 | FAIL | E1 d/q=25/8；E2=4/8 |
| E2 平均边界小于 E1 | FAIL | Test E2 d+q=0.386519428 A；E1=0.385714228 A |
| 不在多数周期超原半宽 | PASS | 所有聚合比例低于 0.5 |
| 无未来特征/测试统计泄漏 | PASS | 特征审计通过 |

阶段 A 总判定为 FAIL。不能用“多数周期门通过”覆盖前三项硬失败。

## 8. 压力和失败场景

71 个 C0 场景中 67 个完成，4 个 Test 场景提前结束：

- test_vdc_44：0.0047 s；
- test_dyn_500_20_3ms：0.0030 s；
- test_transition_step_300：0.0506 s；
- test_transition_step_500：0.0514 s。

失效前数据全部保留。最严重场景证据包括：

- test_dyn_500_20_3ms：E1 d/联合覆盖率仅 0.137931034；
- test_unseen_noise_seed_6102：E2 q/联合覆盖率仅 0.697197197/0.683683684；
- test_transition_step_500：E2 最大 d/q 边界达到 4.065960619/1.796552793 A；
- test_high_negid_500_-6：E2 d 边界超原半宽率为 0.995495495。

详见 STRESS_TEST_REPORT.md 和 WORST_CASE_SUMMARY.csv。

## 9. 鲁棒收紧推导与不可用性

收紧公式为：

\[
\Delta_{d,q,\mathrm{rob}}=\max(0,\Delta_{d,q}-\epsilon_{d,q}),
\qquad
J_{d,q,\mathrm{rob}}=\Delta_{d,q,\mathrm{rob}}^2.
\]

若名义预测误差落在收紧半宽内且实际残余落在 epsilon 边界内，三角不等式可以证明实际误差落在原 0.4 A 半宽内。完整推导见 ROBUST_TIGHTENING_DERIVATION.md。

但该证明依赖“残余边界真实覆盖”。本次 E1/E2 的 Test 证据不满足该前提，因此不能把形式上的收紧公式称为已验证的鲁棒保证。

## 10. 执行时间边界

C0 正式场景的 MATLAB 主机控制器时间为 mean/p95/max = 0.000426323/0.000814080/0.002017100 s，均高于 100 µs 采样周期。该数字不是硬件计时。

C1/C2/C3 没有运行，所以其边界计算、收紧、几何层和控制器总时间均为 NaN。不能声明鲁棒控制器满足 100 µs 实时要求。

## 11. 最终判定

本次专项只有一个允许的结论：

**D. 残余边界不足。**

这不是 E，因为路径、逐点回归、时序对齐、场景拆分和特征泄漏审计均通过。失败来自 Calibration 拟合边界在独立 Validation/Test 上的覆盖和宽度泛化不足。

在新的、预注册的边界识别方案通过阶段 A 之前，不得恢复阶段 B，也不得用任意安全系数、测试集再拟合或 offline Oracle 结果绕过该结论。

