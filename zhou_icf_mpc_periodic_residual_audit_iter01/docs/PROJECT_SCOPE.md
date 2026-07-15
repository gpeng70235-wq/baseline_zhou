# Project Scope

本工程只审计 B0 原始 Zhou `k→k+2` 电流预测残差中的 6 阶/12 阶电角同步分量、跨周期/跨工况重复性、与独立 Jd/Jq false-safe 的描述性关联，以及 held-out 离线约束分类变化。

## 允许

- 读取并冻结 B0 数据。
- 时间域、FFT、电角度域 order tracking。
- calibration 周期拟合与 held-out 周期/工况验证。
- offline counterfactual constraint classification。

## 禁止

- 修改 Zhou 控制器、plant、S2、Jd/Jq 上限或矢量逻辑。
- 继续 dual-timescale F/alpha、RLS、ESO、AULTS 或免疫算法。
- 实现谐振器、谐波注入或周期补偿器。
- 把离线拟合称为闭环性能或把诊断 candidate bank 称为原生决策。

固定约束为 `Jd_limit=Jq_limit=0.16 A^2`，预注册阶次仅为 6 和 12；1—20 阶只作完整谱展示。
