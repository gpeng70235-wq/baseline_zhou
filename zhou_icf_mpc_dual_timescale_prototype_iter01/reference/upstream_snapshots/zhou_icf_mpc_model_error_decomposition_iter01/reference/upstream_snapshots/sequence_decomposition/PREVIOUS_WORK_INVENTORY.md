# 旧工作盘点与可复用边界

## 1. 已经做过什么

### IPMSM 移植与基础门

`zhou_icf_mpc_ipmsm_probe_iter01` 已验证 IPMSM `Ld != Lq` 路径、`Ld=Lq` 退化、`alpha_d/alpha_q` 独立模式以及负 id 的基本闭环行为。它回答的是移植合法性，不是序列/模型误差分解。

### 显式电压可行性与 S2

`zhou_icf_mpc_ipmsm_feasibility_control_iter01` 已建立电流约束矩形与电压六边形交集、S2 feasibility correction、合法三矢量命令合成和无负作用时间回归；包含 500 rpm、20 A、48 V 边界案例。它保留了 selected/pending/applied 和序列字段，但没有把 k+2 总误差分成序列项与模型项。

### 总残差及 E1/E2

`zhou_icf_mpc_ipmsm_robust_constraint_iter01` 已严格定义

```text
e(k) = i_actual(k+2) - i_pred(k+2|k)
```

并按完整场景划分 Calibration、Validation 和 Test，保存 prediction/selected/pending/applied/actual 索引、序列、作用时间、角度、F、alpha、参数尺度及总残差。它已证明 E1/E2 经验边界不能在独立集可靠泛化，阶段 B 未运行。该失败结论必须保留，不得在本项目重建或调参 E1/E2。

### Jd–Jq 扫描

`zhou_icf_mpc_constraint_audit_v1` 已实施 coarse/focused 扫描、跨工况迁移与矢量模式统计。本项目固定 `Jd_limit=Jq_limit=0.16 A^2`，不得重新运行 608 点或同类宽泛扫描。

### 相关平均/序列根因工作

`zhou_a2_average_sequence_rootcause_iter01` 已在其限定模型中对平均输入、逐段序列、角度更新和 RK4/精确解做过诊断，并指出纯平均–序列差异不足以解释其旧问题。但该工程没有完成本项目要求的 IPMSM/S2 闭环三层预测、两周期 selected/pending 对齐、独立 d/q 混淆统计及离线候选重评，因此不能直接回答本项目。

## 2. 旧工程没有做什么

旧 robust 工程没有同时提供以下完整链条：

- `i_pred_avg(k+2|k)`、`i_pred_seq_ul(k+2|k)`、`i_pred_seq_plant(k+2|k)` 与闭环 `i_actual(k+2)` 四者并列；
- `e_sequence_ul/e_model_ul` 与 `e_sequence_plant/e_model_plant` 两套逐轴分解；
- 从 `i(k)` 开始按 pending+selected 两周期最终命令逐段重放；
- 两套恒等式逐样本闭合门；
- 三预测口径下的约束混淆对照；
- 一个清楚声明为“非原生”的离线诊断候选库的 top-1/top-3/模式重评。

旧 A2 工程也没有补齐上述 IPMSM 闭环链条。

## 3. 可以直接复用的结果

- 四个上游的静态报告与机器可读快照，可用作来源确认和回归参考。
- S2 工程的冻结控制器、对象、可行性层和指标函数的字节副本。
- robust 工程的 k+2 对齐规则、命令携带字段、数据按完整场景隔离原则及已知 false-safe 场景标识。
- Jd/Jq 工程已经做过宽泛扫描这一事实，以及 `0.16 A^2` 冻结决定。
- 旧场景配置可用于挑选最小代表集，但不能整批复跑 71 场景或构造新宽扫。

## 4. 禁止重复的实验

- 608 点 Jd–Jq coarse/focused 扫描及等价大网格。
- E1/E2 经验边界拟合、验证、测试或用新安全系数绕过旧结论。
- 157/71 场景原样全量复跑，仅为重新得到已知总残差。
- 为寻找“好看结果”而无预注册地扫描 Vdc、速度、参考斜率或参数误差。

## 5. 可直接重新分析的旧数据

robust 数据中的 `id_pred_k2_A/iq_pred_k2_A`、`id_actual_k2_A/iq_actual_k2_A`、`e_d_A/e_q_A`、Fd/Fq、alpha、角度、参数尺度、selected/applied 序列和索引可用于：

- 验证字段语义和 k+2 对齐；
- 选择代表工况与已知 false-safe 段；
- 与新正式运行做基线/分布 sanity check。

这些旧 CSV 不能凭后处理补出缺失的 pending+selected 两周期 plant 状态轨迹时，就不得伪造新字段。

## 6. 必须重新运行才能获得的新字段

- 最终 S2 后 pending 与 selected 命令的每段角度/起止状态（若旧轨迹未完整记录）。
- `i_pred_seq_ul` 和 `i_pred_seq_plant` 两周期重放结果。
- 两套分解、闭合误差、逐预测口径的 Jd/Jq pass 状态。
- S2 前后同一时刻的诊断关系、序列模式与作用时间不平衡度。
- 离线诊断候选库的三模型预测与排序。
- 本工程配置下的重复性、计算时间和 14 类图。

## 7. 为什么旧结论不能回答本项目

E1/E2 只把所有未解释因素合并到总残差，不能区分平均输入表示与 F/模型误差。S2 工程关注电压命令合法性，Jd/Jq 工程关注约束参数，A2 工程的对象和闭环覆盖又不满足当前 IPMSM/S2 两周期要求。只有本项目把同一实际闭环样本与三层预测严格对齐后，才能判断误判的主导来源。

## 8. 旧 robust 字段专项检查

| 要求字段/分析 | 旧 robust 状态 | 是否足以停止新开发 |
|---|---|---:|
| `i_pred_avg`（旧名 `id/iq_pred_k2_A`） | 有 | 否 |
| `i_actual(k+2)` | 有 | 否 |
| `e_total`（旧名 `e_d/e_q_A`） | 有 | 否 |
| `i_pred_seq_ul` | 无完整正式字段 | 否 |
| `i_pred_seq_plant` | 无完整正式字段 | 否 |
| `e_sequence` 与 `e_model` | 无 | 否 |
| 三模型候选重新排序 | 无 | 否 |

结论：不存在“旧 robust 已完整实现同一分解”的证据，防重复停止条款不触发。
