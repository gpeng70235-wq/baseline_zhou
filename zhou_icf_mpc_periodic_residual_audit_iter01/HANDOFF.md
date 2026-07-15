# HANDOFF — Zhou 周期残差机理审计

1. **项目目标。** 审计 B0 的 6/12 电角同步残差、重复性、false-safe 关联和 held-out 离线分类价值。
2. **双时间尺度为何停止。** P 在五工况把 false-safe 3.526239% 恶化至 3.753128%，向量 RMS 0.0613189 A 恶化至 0.132352 A；B1/B2/RLS 均未过门禁。
3. **B0 数据源。** model-error Git 冻结快照的 24 工况 `model_error_samples.csv`，本地字节级副本在 `reference/frozen_data`；未重跑 B0。
4. **时序与残差。** row k 保存 `id/iq(k)`、`id_pred/iq_pred(k+2|k)` 和 `id_actual/iq_actual(k+2)`；`e=actual-pred`。
5. **有效窗口。** 注册 steady、完整结束、非 stress、至少3周期、非零速度；FFT 另要求速度 CV≤1% 与 20阶 Nyquist。
6. **FFT。** 整数周期、去均值/线性趋势、Hann 描述谱，并行无窗精确正弦回归，记录噪声底/泄漏/aliasing。
7. **Order tracking。** 每周期256电角点，线性重采样，6+12联合拟合，正/负旋转复系数均保存。
8. **6阶。** 稳定主域工况 11，SNR 中位数 27.0248 dB，最大 CV 5.755%，最小 R 0.991435。
9. **12阶。** 稳定主域工况 11，SNR 中位数 18.572 dB，最大 CV 21.688%，最小 R 0.947943。
10. **幅值重复性。** 两阶全部稳定行通过 CV≤30% 与 calibration/validation 幅值门禁。
11. **相位重复性。** 两阶稳定行最小 R 如上，均通过 R≥0.7；工况间 false-safe 相位仍异质。
12. **跨周期。** 6+12 leave-one-cycle-out 正迁移率 100.000%，通过。
13. **跨工况。** 同速 leave-one-case-out 正迁移率 60.000%，通过最低门槛但非普遍。
14. **false-safe 关联。** 6/12 阶分别有 5/7 个主域工况满足事件数与相位集中条件；只称关联。
15. **离线反事实。** 仅6/仅12/6+12 false-safe 相对下降 16.949%/15.254%/25.424%；组合 FA +0.45427 pp，RMS -12.159%。
16. **A—E 结论。** A — stable_periodic_residual_with_material_false_safe_contribution。
17. **是否允许下一原型。** YES，只允许独立项目，不得在本工程实现。
18. **下一工程名。** `zhou_icf_mpc_periodic_compensation_prototype_iter01`。
19. **关键路径。** CSV `results/summary`，逐样本 `results/raw/periodic_residual_samples.csv`，图 `results/figures`，正式报告 `docs/PERIODIC_RESIDUAL_AUDIT_REPORT.md`。
20. **上游 SHA-256。** BEFORE/AFTER 共 1099/1099 行；added/deleted/modified=0/0/0，`PASS`。
21. **已知限制。** 见 `docs/KNOWN_LIMITATIONS.md`，尤其 100/200 rpm 周期不足、500 rpm 单一有效主域、400 rpm 跨工况负迁移与单工况 FA 异质性。
22. **措辞禁令。** 所有修正结果只能称 offline counterfactual constraint classification；禁止称闭环算法或控制性能。
