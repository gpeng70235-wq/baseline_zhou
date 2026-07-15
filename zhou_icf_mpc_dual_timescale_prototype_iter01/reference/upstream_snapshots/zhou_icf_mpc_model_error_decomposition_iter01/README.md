# Zhou ICF-MPC IPMSM 一阶超局部模型误差分解

这是一个完全隔离的离线诊断工程。它冻结五个上游，只重放闭环数据并建立 P0--P5 预测器阶梯，用替换实验区分 `F` 估计、`alpha` 输入增益、两拍冻结/离散化及剩余对象结构误差；不修改原控制器。

## 已完成结果

- 工程：`C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_model_error_decomposition_iter01`
- 数据：`24` 个工况，`24153` 个有效 k→k+2 样本（上一周期 oracle 的公共交集 `24129`）。
- 基线：`10/10` 通过；Jd/Jq 上限均冻结为 `0.16 A^2`。
- 正式结论：**C — F and alpha jointly dominate**。
- 下一路线：separate compute-bounded extended-affine ultralocal study; independently audit the stable 6x/12x electrical-periodic residual before considering any resonator。该建议不会在本工程自动实现。
- 上游文档生成时校验：**PASS**，变化文件数 `0`。
- 图表：`15/15` 已生成。

## 核心数值

口径：**全部 24 工况（含独立标记的 stress test）**

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

A--F 门禁使用 `ENGINEERING_PRIMARY`（排除 stress test），其 P0 false-safe 为 **3.029664%**；全量复现口径为 **3.059661%**。两个口径在所有报告中分开显示。

## 一键运行

```matlab
cd('C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_model_error_decomposition_iter01')
run_model_error_decomposition()
```

无参数等价于 `all`；还支持 `inventory`、`baseline`、`audit`、`prototype`。`prototype` 只记录禁止门禁。详见 [RUN_AND_REPRODUCE.md](RUN_AND_REPRODUCE.md)。

## 证据入口

- 逐样本主表：[`results/raw/model_error_samples.csv`](results/raw/model_error_samples.csv)
- 汇总目录：[`results/summary`](results/summary)
- 正式报告：[`docs/MODEL_ERROR_DECOMPOSITION_REPORT.md`](docs/MODEL_ERROR_DECOMPOSITION_REPORT.md)
- 决策：[`docs/DECISION_AND_NEXT_STEP.md`](docs/DECISION_AND_NEXT_STEP.md)
- 完整交接：[`HANDOFF.md`](HANDOFF.md)
- 15 类图：[`results/figures`](results/figures)

## 解释边界

P2c/P3c 使用当前周期未来端点，是非因果上界；P5 是对象重放下界；P2b/P3b/P4 需要真实对象参数。离线候选集是诊断 bank，不是 Zhou 连续几何候选空间，因此 ranking 只作次级证据。`di/dt=F+alpha*u` 还存在 gauge 不可辨识性，独立贡献只在本报告注册的物理拆分与 MSE/Shapley 口径内成立。
