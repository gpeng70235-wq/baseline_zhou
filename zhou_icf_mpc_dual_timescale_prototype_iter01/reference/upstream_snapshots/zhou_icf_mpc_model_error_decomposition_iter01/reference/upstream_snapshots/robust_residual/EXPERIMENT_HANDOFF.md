# 实验交接

## 当前不可变结论

正式 run_id 20260713_122037_robust_constraint 的阶段 A 已失败，最终判定为 D。阶段 B 必须保持停止。

任何后续人员首先应读取：

1. ROBUST_CONSTRAINT_DECISION.md
2. FINAL_ROBUST_CONSTRAINT_REPORT.md
3. COVERAGE_REPORT.md
4. BOUND_COMPARISON.csv
5. SCENARIO_COVERAGE_MATRIX.csv
6. BOUND_IDENTIFICATION_FAILURE_REPORT.md
7. RESIDUAL_ALIGNMENT_AUDIT.md
8. BASELINE_COMPARISON.csv

## 权威运行产物

阶段 A 二进制和轨迹位于：

    results\stageA\20260713_122037_robust_constraint

其中：

- residual_datasets.mat：冻结的 Calibration/Validation/Test 对齐残余；
- bound_models.mat：E0/E1/E2 模型；
- stageA_data.mat：正式阶段 A 汇总；
- C0_scenario_runs.csv：71 个 C0 场景汇总；
- A0_C0_trace.csv、A0_C0_summary.csv：正式基线回归场景；
- residual_feature_schema.csv：在线特征字段审计。

根目录的 BOUND_COMPARISON.csv、SCENARIO_COVERAGE_MATRIX.csv、RESIDUAL_STATISTICS.csv、RESIDUAL_CONDITION_MATRIX.csv 和 WORST_RESIDUAL_TRACES.csv 是机器可读审计入口。

## 已确认事实

- 数据拆分为完整场景 17/22/32，拟合前冻结。
- Calibration/Validation/Test 有效对齐残余行分别为 33966/43956/57037。
- E1/E2 都只由 Calibration 拟合并在 Calibration 100% 覆盖。
- E1 Test d/q/joint = 0.998474674/0.979241545/0.977961674。
- E2 Test d/q/joint = 0.998246752/0.978645441/0.977348037。
- E1/E2 Test 最长 d/q 漏覆盖 = 25/8 和 4/8 周期。
- E2 Test 平均 d+q 边界为 0.386519428 A，未优于 E1 的 0.385714228 A。
- C0 正式 2000 周期逐点回归全部公共信号最大绝对误差 0。
- 4 个提前结束的 Test 场景及其失效前数据均已保留。

## 不得执行

- 不得在本 run_id 下运行或补写 C1/C2/C3 结果。
- 不得把任何早期 smoke run 当作正式阶段 B 证据。
- 不得以任意安全系数缩放 E1/E2。
- 不得用 Validation/Test 重新拟合本次模型。
- 不得使用未来实际电流、future Case/voltage/duration、真实 plant scale 或 offline Oracle 进入在线路径。
- 不得把 NaN/NOT RUN 改为 0。
- 不得修改三个冻结项目或让 MATLAB 路径依赖它们。

## 合法的后续研究

如果要继续研究，应建立新的迭代工程，而不是覆盖本工程。新迭代必须：

1. 在看新 Test 结果前预注册新的完整场景拆分和覆盖目标；
2. 解释并专门处理未见测量噪声 q 轴漏覆盖、快速动态 d 轴漏覆盖和负 id 下 E2 过宽，但不能直接用当前 Test 拟合；
3. 区分确定性上界和经验概率覆盖；若改用 conformal，必须预注册置信/容差口径；
4. 先独立通过新的阶段 A，再允许阶段 B；
5. 重新执行 C0 逐点回归、路径隔离、时序对齐和特征泄漏审计。

建议将当前 Test 保留为已使用审计集；新迭代应引入新的独立随机种子和未见组合，避免把当前失败样本变成隐性训练数据后仍称为独立验证。

## 复现命令

仅用于新的审计运行，不要覆盖正式 run_id：

    restoredefaultpath
    cd('C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_robust_constraint_iter01')
    project = initialize_project("NEW_STAGEA_RUN_ID");
    stageA = zhou_robust.run_stageA(project);

若新运行阶段 A 仍失败，应立即停止，不调用 zhou_robust.run_robust_case 的 C1/C2/C3 方法。

