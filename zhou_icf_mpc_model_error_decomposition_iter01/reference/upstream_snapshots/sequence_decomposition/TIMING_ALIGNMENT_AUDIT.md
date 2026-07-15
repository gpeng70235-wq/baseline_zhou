# k/k+1/k+2 时间对齐审计

## 固定时序

本工程唯一允许的主对齐是：

```text
在 k 采样并选择 selected(k)
pending(k) 在 [kTs,(k+1)Ts) 施加
selected(k) 在 [(k+1)Ts,(k+2)Ts) 施加，即 applied(k+1)
目标实际值为 i_actual(k+2)
```

简写为：

`selected(k) -> applied(k+1) -> actual(k+2)`

因此从 `x(k)` 构造与原 `i_pred_avg(k+2|k)` 同期的独立预测时，必须顺序重放 `pending(k)` 和 `selected(k)` 两个采样周期。只从 `i_predicted(k+1)` 重放第二周期可以作为内部交叉检查，但不能隐藏第一周期的命令或状态来源。

## 索引表

| 物理区间/边界 | 命令/状态 | 记录要求 |
|---|---|---|
| 边界 k | `x(k)`, `theta(k)`, `Fhat(k)`, refs(k) | 预测快照，`prediction_index=k` |
| k→k+1 | `pending(k)=selected(k-1)` | 最终矢量 ID、顺序、作用时间、S2 后命令 |
| 边界 k+1 | 中间预测/重放状态 | UL 与 plant 层均保留，供一周期闭合检查 |
| k+1→k+2 | `selected(k)=applied(k+1)` | final selected 的序列签名必须与 applied(k+1) 一致 |
| 边界 k+2 | `i_actual(k+2)` | 来自闭环对象，`actual_index=k+2` |

## 两周期重放角度

- pending 各段中点角：`theta(k) + omega_e*(segment_start + duration/2)`。
- selected 各段中点角：`theta(k) + omega_e*(Ts + segment_start + duration/2)`。
- plant-model 重放不得只在段中点冻结电角度；状态中的电角度应随微分方程/固定 `omega_e` 连续演化，段中点角只用于等效电压审计。
- 控制器几何选择在 execution-midpoint 模式使用与下一执行周期相容的几何角；不得以 selection-angle 的 dq 电压替换执行等效 dq 电压。

## 命令一致性检查

每个有效样本至少检查：

1. `pending(k)` 与实际在区间 k→k+1 执行的命令序列签名一致。
2. `selected(k)` 与 `applied(k+1)` 的矢量 ID、顺序和每段时长一致。
3. 每个最终命令作用时间非负，和为 Ts；零矢量类型/ID 保持一致。
4. S2 触发时使用 S2 后命令；原命令只作对照。
5. selected、pending 和 applied 的平均 alpha-beta 电压由各自最终序列重新核验。
6. 前一周期末矢量与当前起始矢量用于跨周期开关动作统计，但不能改变状态对齐。

## 实际值来源

`i_actual(k+2)` 必须是完整闭环对象在两周期命令执行后记录的采样值。plant-model-sequence 离线重放即使与对象使用相同方程，也只是诊断预测，不能覆盖 actual 列。

## 边界样本处理

- 初始化历史不足的样本可保留原始轨迹，但须用明确 `alignment_valid=false` 排除在正式分解外。
- 末尾两个预测行没有可观测的 k+2 实际值，必须排除，不得用 NaN 以外的填充值伪装完整。
- 参考值用于 Jd/Jq 时必须记录其时间语义；主比较应使用与原控制器内部 Jd/Jq 相同的 reference 快照，另行报告实际 k+2 reference 对照时要显式区分。

## 闭合门

逐轴逐样本计算：

```text
r_ul    = e_total - e_sequence_ul - e_model_ul
r_plant = e_total - e_sequence_plant - e_model_plant
```

两者必须在配置容差内。若失败，按下列顺序排查：索引 → pending/selected/applied → S2 前后命令 → 时长和 → 零矢量 → 电角度/Park 时刻 → reference 时间 → 对象是否真逐段执行。闭合失败时 A–D 禁止，最终只能进入实现/时序错误 E。

## 正式审计结果

- 有效对齐样本数：**24,153**。
- selected(k)→pending/applied(k+1) 可比较对：**24,129**；命令 ID/持续时间携带失败数：**0**。
- UL 恒等最大闭合误差：**1.1102230246e-16 A**（两套恒等式总体最大值）。
- plant 两周期重放与闭环 actual 最大差：**0 A**。
- UL 逐段与记录平均预测最大差：**2.0947646133e-14 A**。
- 时间对齐门：**PASS**。
