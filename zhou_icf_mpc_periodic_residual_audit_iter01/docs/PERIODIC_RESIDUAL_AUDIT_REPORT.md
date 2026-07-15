# Periodic Residual Audit Report

## Formal outcome

**A — stable_periodic_residual_with_material_false_safe_contribution**。这是纯诊断结论；闭环轨迹和控制器没有改变。

## Registered evidence

- 正式主域有效工况/完整电气周期：**11 / 39**（含次级动态证据为 14 / 49）。
- 6阶/12阶稳定出现工况：**11 / 11**。
- 6阶/12阶主域峰值 SNR 中位数：**27.0248 / 18.572 dB**；保守最小值 19.6684 / 8.87022 dB。
- 最大周期幅值 CV：**5.755% / 21.688%**；最小相位 R：**0.991435 / 0.947943**。
- 频率同步：**YES**；跨周期正迁移率 100.000%；同速跨工况正迁移率 60.000%。
- 具相位集中且事件数足够的主域工况（6/12阶）：**5 / 7**。关联是描述性的，不称因果。

## Held-out offline counterfactual constraint classification

- 仅6阶：false-safe 相对下降 **16.949%**。
- 仅12阶：false-safe 相对下降 **15.254%**。
- 6+12阶：false-safe 相对下降 **25.424%**，false-alarm **+0.45427 pp**，预测向量 RMS 下降 **12.159%**。
- B0/6+12 held-out RMS：`0.0386242 A` / `0.0339279 A`。

## Gate decision

12 项最低门槛全部通过：**YES**。因此只允许下一独立工程研究轻量周期补偿原型；本工程本身没有实现补偿器。
冻结上游复核：`PASS`，added/deleted/modified = `0/0/0`。
