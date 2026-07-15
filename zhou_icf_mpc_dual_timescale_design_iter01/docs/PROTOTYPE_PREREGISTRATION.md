# Prototype Preregistration

下一隔离闭环工程固定命名：`zhou_icf_mpc_dual_timescale_prototype_iter01`。本设计工程不创建它。

唯一允许的组：B0 原 Zhou predictor；B1 仅慢投影 alpha；B2 慢 alpha + 快 F；P = B2 + excitation gate + post-S2 actual voltage + latched decision trend；RLS = 受约束二参数上限对照。不得增加 ESO/AULTS/免疫/谐振器组。

冻结项：同一 plant、24 工况、Jd/Jq limits、单/双/三矢量逻辑、candidate generation、S2、指标与样本 mask。每组 3 次确定性重复；同一初值和输入日志。

生死门槛全部满足才存活：

1. `ENGINEERING_PRIMARY` false-safe 相对 B0 下降至少 50%，绝对不高于约 1.52%；
2. false-alarm 不高于 2%；predictor RMS 不高于 B0 的 110%；
3. THD 与 torque ripple 各自恶化不超过 5%；
4. core、dynamic、parameter cohorts 都有重复收益，不能只靠 stress；
5. DSP 新增 cycle count 不超过 B0 25%；
6. 无真实 Ld/Lq、无未来 actual current；
7. S2 triggered subset 的 alpha/F 有界且不发散；
8. 三次结果完全确定，SHA 冻结通过。

必须记录：每轴 alpha/F、projection hit、所有 gate/reason、u_app segment log 与 reconstruction residual、window energy/rcond、u_hp/y_hp、native decision margin/gap、latched gate、predicted/actual Jd/Jq、false-safe run、false-alarm、mode flip、RMS/THD/torque、每模块 DSP cycles。

顺序：先 B0 回归；再 B1 分离慢增益风险；再 B2 验证 gauge 协同；最后 P 验证 gates/S2/decision 机制；RLS 只作上限对照。任一安全、时序、实际电压或确定性门失败即停止后续组。
