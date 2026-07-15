# Zhou ICF-MPC IPMSM 独立 dq 鲁棒约束收紧专项

本工程是从已验收的电压可行性控制器逐文件复制后建立的独立专项工程。正式运行编号为 20260713_122037_robust_constraint。

## 最终状态

**结论 D：预测残余边界不足。**

阶段 A 已完成，阶段 B 因预注册硬门失败而停止。C1、C2 和 C3 没有进入正式控制实验；其性能、THD、转矩纹波、开关动作、S2/S3 比例和执行时间均为 NOT_RUN_STAGE_A_GATE_FAILED，不得用零替代。

阶段 A 的关键证据：

| 方法 | 数据集 | d 覆盖率 | q 覆盖率 | 联合覆盖率 |
|---|---|---:|---:|---:|
| E1 全局轴向边界 | Calibration | 1.000000 | 1.000000 | 1.000000 |
| E1 全局轴向边界 | Validation | 0.997178997 | 0.983210483 | 0.980389480 |
| E1 全局轴向边界 | Test | 0.998474674 | 0.979241545 | 0.977961674 |
| E2 调度轴向包络 | Calibration | 1.000000 | 1.000000 | 1.000000 |
| E2 调度轴向包络 | Validation | 0.991627992 | 0.982687233 | 0.974952225 |
| E2 调度轴向包络 | Test | 0.998246752 | 0.978645441 | 0.977348037 |

确定性边界的 Test 单轴门槛为 0.999。E1、E2 均未通过；最长连续漏覆盖分别达到 E1 的 d/q = 25/8 周期和 E2 的 d/q = 4/8 周期。E2 在 Test 上的 d+q 平均边界宽度为 0.386519428 A，略大于 E1 的 0.385714228 A，也未通过平均宽度门。

## 可审计性

- 数据按完整场景冻结：Calibration 17、Validation 22、Test 32。
- 残余严格定义为 e(k)=i_actual(k+2)-i_pred(k+2|k)；末尾两个无法对齐的预测行不填充。
- E1/E2 只使用 Calibration 拟合；E2 在线特征不含未来量、真实 plant scale 或测试集统计量。
- PATH_ISOLATION_AUDIT.md 记录 restoredefaultpath 已执行，所有关键函数解析到本工程。
- BASELINE_COMPARISON.csv 的聚合行证明正式 C0 场景 2000 行、全部公共控制信号最大绝对误差为 0，逐点回归通过。
- 4 个未完成压力场景没有被隐藏；其失效前轨迹和来源完成标志均保留。

## 正式产物入口

- FINAL_ROBUST_CONSTRAINT_REPORT.md：完整结论与证据。
- ROBUST_CONSTRAINT_DECISION.md：A–E 唯一判定。
- COVERAGE_REPORT.md：覆盖率、边界宽度和门槛审计。
- ROBUST_TIGHTENING_DERIVATION.md：独立 dq 收紧与三角不等式证明。
- STRESS_TEST_REPORT.md：压力场景及失败场景。
- EXECUTION_TIME_REPORT.md：MATLAB 主机计时及不可声明事项。
- ROBUST_CONTROL_COMPARISON.csv：C0 正式基线和被门控停止的 C1/C2/C3。
- WORST_CASE_SUMMARY.csv：最差场景索引。
- BOUND_COMPARISON.csv、SCENARIO_COVERAGE_MATRIX.csv：机器可读阶段 A 结果。
- RESIDUAL_STATISTICS.csv、WORST_RESIDUAL_TRACES.csv：残余统计和最差轨迹。
- tests/TEST_REPORT.md、tests/test_results.csv：测试审计。

## 复现边界

从新 MATLAB 会话运行阶段 A 时，应使用新的 run_id，避免覆盖正式结果：

    restoredefaultpath
    cd('C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_robust_constraint_iter01')
    project = initialize_project("NEW_STAGEA_RUN_ID");
    stageA = zhou_robust.run_stageA(project);

不得在本次正式结论下继续调用 C1/C2/C3。若未来重做边界识别，必须建立新的迭代工程、重新预注册完整场景划分，并保持本工程及三个冻结项目只读。

