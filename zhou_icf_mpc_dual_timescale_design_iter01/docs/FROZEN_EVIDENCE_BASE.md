# Frozen Evidence Base

本设计不重跑 24 工况、不重做 P0-P5，也不把 oracle 变体称为可部署算法。冻结结果复核如下：

| 证据 | 冻结值/结论 |
|---|---:|
| P0 全量 false-safe | 3.059661% |
| P0 `ENGINEERING_PRIMARY` false-safe | 3.029664% |
| P3b false-safe | 0.807353% |
| P4 false-safe | 0.679005% |
| P5 false-safe | 0% |
| F / alpha / structure 解释份额 | 53.88% / 28.66% / 17.46% |

P1 和 P2b 降低 false-safe，但全量 RMS 分别约 0.3131 A 和 0.3121 A，false-alarm 分别约 16.59% 和 17.34%，显著差于 P0。P3a/P3b 的联合一致替换远优于将 original-gauge F 与 oracle alpha 随意拼接，证明 F 与 alpha 必须在同一 gauge 下协调更新。

P0 使用两拍冻结 F/alpha；P3b、P4 依赖真实 plant 状态或参数；P5 是对象方程与 RK4 重放下界。它们只用于误差归因。离线候选 bank 在冻结 CSV 中明确标记为 `offline_diagnostic_candidate_bank_not_native_Zhou_candidates`，其 top-1 不能替代原生连续几何候选。

前序 sequence 分解的 average-vs-piecewise frozen-ultralocal residual/total 为 `1.02737154281e-13`，仅浮点量级；该路线已停止。本工程只保留时序回归断言。

证据来源是只读复制件 `reference/upstream_snapshots/model_error`，原件路径和逐文件哈希见 `audit`。
