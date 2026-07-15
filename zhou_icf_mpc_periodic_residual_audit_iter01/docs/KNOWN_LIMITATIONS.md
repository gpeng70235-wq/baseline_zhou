# Known Limitations

1. 100/200 rpm 的 nominal/light core 稳态段不足 3 个完整电气周期，按预注册规则排除；正式主域由 300/400/500 rpm 的 11 个完整工况组成。
2. 500 rpm 有效主域只有 C09 S2 boundary；固定速度同步覆盖三组速度，但 500 rpm 跨工况迁移证据不足。
3. 同速 leave-one-case-out 6+12 仅 60.000% 为正，400 rpm 参数失配组存在负迁移；任何原型不得假设单一全局系数。
4. 聚合 false-safe 相位集中度低于若干单工况，相位关联具有工况异质性；报告只称关联。
5. 6+12 离线分类虽过聚合门槛，部分单工况 false-alarm 增量超过 0.5 pp；原型必须设置单工况安全门禁。
6. 电角度端点存在小比例线性外推，比例与插值往返 RMS 已逐行保留；FFT/精确回归/order tracking 一致且无 aliasing。
7. 固定 Jd/Jq=0.16 A²；未重扫阈值，未重构原生候选 bank。
8. 全部改善均为 held-out offline counterfactual constraint classification，不是闭环、实时或硬件性能。
9. 结论仅覆盖冻结的 24 工况、24,153 行 B0 数据和 R2024b 实现。
