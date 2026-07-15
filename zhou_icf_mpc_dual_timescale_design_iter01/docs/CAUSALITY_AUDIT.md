# Causality Audit

| 检查 | 结果 | 证据 |
|---|---|---|
| 使用未来实际电流 | 否 | 更新器只接收 `i(k),i(k-1)`；预测函数无 actual k+1 参数 |
| 使用真实对象参数 | 否 | 参考配置无 Ld/Lq/Rs/psi；alpha 初值来自 controller configuration |
| 使用 P2b/P3b/P5 信息 | 否 | 仅在冻结证据文档引用其归因；代码无 oracle 输入 |
| 使用 S2 前目标电压 | 否 | F 接口明确为 `u_app(k-1)_post_S2_equivalent` |
| k/k+1/k+2 对齐 | 通过 | 两个显式 Ts 步；pending 后接 final selected |
| 原生/离线候选混淆 | 否 | gate 只接受 `native_selection_valid` 和原生 margin/gap |
| mode/Jd/Jq/S2 被修改 | 否 | 本工程没有其实现或调用；趋势只输出 F_pred |

因果顺序为：采样 i(k)；读取已完成 `u_app(k-1)`；更新 LP/high-pass；条件允许时更新 alpha；用 posterior alpha 更新 F；用上一拍锁存的 decision gate 形成 F_pred；完成 Zhou 两拍预测。当前行原生决策只产生下一拍 gate，不回写本拍，故无代数环。

S2 触发时，只要最终执行段可重构，输入仍是因果且可信；未知裁剪/日志缺失时两个估计器均冻结。差分噪声风险没有被隐藏，靠门控/epsilon/慢更新降低，仍列为原型可证伪项。

单元测试 `test_no_future_data`、`test_s2_applied_voltage_usage`、`test_dq_axis_independence` 与 `test_path_isolation` 固化这些约束。
