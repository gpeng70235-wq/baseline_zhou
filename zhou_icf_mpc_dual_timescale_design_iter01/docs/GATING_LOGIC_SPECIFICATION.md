# Gating Logic Specification

## Excitation gate `g_exc_x`

每轴同时满足：

```text
abs(u_hp_x) > u_hp_min_x
sum_window(u_hp_x^2) > E_u_min_x
rcond(Phi_x' Phi_x) >= rcond_min_x, Phi_x=[1, normalized u_hp_x]
zero_vector_run <= 3
abs(residual_jump_x) <= 5e4 A/s
history_valid = true
```

实现预算使用滚动和与闭式 2x2 conditioning proxy，不在线求逆。任一失败只冻结该轴 alpha 并记录原因；只要实际执行电压可信，F 仍更新。长期冻结后要求连续 3 个 good windows 才重新激活，首个高利用率窗口仍降步长。

## S2 input-quality gate `g_s2`

S2 是否触发不是冻结条件。以下条件同时满足时，即使 S2 修改命令也可更新：最终执行矢量 ID 有效；各段时长有限、非负且总和等于 Ts；Vdc/矢量表、theta、omega 与日志完整；segment-midpoint 重构成功；没有“未知裁剪”。`u_app` 必须来自执行完成的 post-S2 命令。

当利用率不低于 0.90 时 alpha 步长乘 0.25。若目标命令被裁剪但最终段时长没有记录、日志丢失或重构不一致，则 alpha 和 F 都冻结；不得退回使用目标电压。

## Decision-margin gate `g_decision`

输入只允许原生 Zhou 当前选择的 `Jd_pred/Jq_pred` 与原生 mode gap，不允许离线候选 bank。触发条件：

```text
m_J = min(Jd_limit-Jd_pred, Jq_limit-Jq_pred)
near_safe = 0 <= m_J <= 0.02 A^2
near_mode = abs(native_mode_gap) <= 0.01 A^2
g_decision_next = native_selection_valid && (near_safe || near_mode)
```

`g_decision_next(k)` 在选择结束后锁存，成为下一行的 `g_decision_latched(k+1)`，避免同拍循环依赖。false-safe 风险在原型中记录“预测安全而实际 k+2 违反”的比率与连续 run；模式风险记录相对 B0 的 mode flip 和相邻 mode gap。趋势项不改阈值，且必须单独记录 gate-on/off 的风险。

完整真值表见 `results/summary/gate_truth_table.csv`，参考实现见 `src/+design/reference_gate_logic.m`。
