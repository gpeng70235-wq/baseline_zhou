# Zhou ICF-MPC IPMSM 多矢量序列误差分解专项

本工程用于回答一个限定问题：原控制器的平均电压预测与最终多矢量序列逐段执行之间的差异，是否是独立 d/q 电流约束误判的主要来源。工程只做离线诊断，不修改冻结控制器、IPMSM 对象、S2 电压可行性层、F 估计器或约束值。

项目绝对路径：

`C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_sequence_decomposition_iter01`

## 正式结论

2026-07-15 正式运行了 24 个代表工况，得到 24,153 个严格 k→k+2 对齐样本，基线 10/10 通过，上游 1,968 个文件 before/after 变化为 0。结论为 **B：一阶超局部模型/F 估计误差主导**。纯 UL 序列项/总残差为 `1.0274e-13`，模型项/总残差为 `1.0`；原平均预测与 UL 逐段预测的 false-safe 均为 `3.0597%`。prototype 门关闭。详见 `docs/SEQUENCE_DECOMPOSITION_REPORT.md`。

## 冻结上游

本工程确认并冻结以下四个上游；运行时不得把它们加入 MATLAB 路径，也不得修改其中任何文件：

1. `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_probe_iter01`
2. `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_feasibility_control_iter01`
3. `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_robust_constraint_iter01`
4. `C:\Users\catkin\Documents\baseline_zhou\baseline_zhou-main\baseline_zhou-main\zhou_icf_mpc_constraint_audit_v1`

逐文件冻结证据位于 `SOURCE_SHA256_BEFORE.csv`；运行结束后的复核位于 `SOURCE_SHA256_AFTER.csv` 和 `FROZEN_UPSTREAM_VALIDATION.csv`。复制文件的字节一致性与用途记录在 `COPIED_FILE_PROVENANCE.csv`。

## 一键运行

在 MATLAB R2024b 的全新会话中执行：

```matlab
cd('C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_sequence_decomposition_iter01')
run_sequence_decomposition()
```

默认调用等价于 `run_sequence_decomposition('all')`。可选模式为 `inventory`、`baseline`、`audit` 和 `prototype`。`all` 不运行原型；`prototype` 默认被门控，只有正式结论为 A 或 C 且全部准入条件通过后才允许人工调用。

入口首先重置 MATLAB 路径和函数缓存，只加入当前工程路径。若任一关键函数解析到兄弟工程，审计必须停止。

## 核心时间对齐

控制器在周期 `k` 选择命令；该命令在 `k+1` 周期施加，并与闭环对象的 `i_actual(k+2)` 对齐：

`selected(k) -> applied(k+1) -> actual(k+2)`

离线重放从 `i(k)` 出发，按顺序重放 `pending(k)` 与 `selected(k)` 两个完整采样周期。末尾两个没有可观测 `k+2` 的预测样本不得补值。

## 三层预测

- `i_pred_avg(k+2|k)`：直接保留原控制器的两步、平均等效 dq 电压、Euler 预测。
- `i_pred_seq_ul(k+2|k)`：在 `audit/` 中用冻结的 `Fd/Fq` 与 `alpha_d/alpha_q` 对最终序列逐段 Euler 重放。由于 F、alpha 在窗口内冻结，且原控制器使用每段中点角的等效平均电压，该逐段和与平均式在代数上相同；非浮点级差异首先视为实现或时序问题。
- `i_pred_seq_plant(k+2|k)`：用实际 IPMSM 参数、演化电角度及最终序列逐段积分的诊断预测。
- `i_actual(k+2)`：闭环对象实际采样值，禁止用离线重算值替代。

残差恒等式必须先闭合，才允许作 A–E 判断：

```text
e_total = i_actual - i_pred_avg
e_total = e_sequence_ul + e_model_ul
e_total = e_sequence_plant + e_model_plant
```

## 约束与候选解释

冻结约束为 `Jd_limit = Jq_limit = 0.16 A^2`，不得收紧或重标定。

原 Zhou 控制器是连续几何解析选择，不存在原生有限候选表，也没有原生“top-3”。本工程若输出候选 top-1/top-3，只表示预先记录的**离线诊断候选库**内部排序；它不能被表述为原控制器本身的候选排序，亦不反馈闭环。

## 禁止事项

- 不运行 608 点 Jd–Jq 扫描，不重新训练或评估 E1/E2 经验边界。
- 不修改四个冻结上游、复制来的控制器或对象源码。
- 不加入 ESO、RLS、全模型在线估计、神经网络或新的 MTPA。
- 不用压力点替代连续合理工况证据，不在结果生成前实现控制改进。
- 不把 plant-model-sequence 诊断 oracle 当作可在线实现的控制器。

复现细节见 `RUN_AND_REPRODUCE.md`，方法定义见 `docs/PREDICTION_LAYER_DEFINITION.md`，交接状态见 `HANDOFF.md`。
