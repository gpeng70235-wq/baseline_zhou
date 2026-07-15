# Design Requirements From Evidence

冻结归因被转换为以下单一路线约束：

1. F 是主要误差来源，因此必须每个可信采样更新；但不能用 oracle 物理 F 或未来端点。
2. alpha 的独立替换会改变 F 的 gauge；alpha 更新后必须用同一 posterior alpha 重新形成 `F_meas`。
3. d/q 原 alpha 分别为 1250 与 833.333333 A/(V·s)，必须保留两个独立状态、独立上下界和独立门控，不能退化为公共 SPMSM 标量。
4. P1/P2b 的 RMS 与 false-alarm 恶化禁止“只追 false-safe”；下一原型同时约束 RMS、false-alarm、THD 和转矩脉动。
5. P3a/P3b 的联合收益要求 F/alpha 协同但不同带宽：alpha 慢、投影、激励门控；F 快、每拍、吸收剩余低频与耦合。
6. P4 说明第一拍后刷新局部模型有上限收益，但未来真实 `i(k+1)` 不可用；当前设计只用 `i(k),i(k-1),u_app(k-1)`。
7. sequence 已排除；两拍仍采用周期等效 segment-midpoint 电压，不引入逐段新预测器。
8. 增强只通过预测器输出影响 Zhou 几何决策；Jd/Jq 阈值、模式逻辑、候选生成和 S2 均不变。
9. 决策趋势仅在原生决策敏感区锁存；不得由离线候选排名触发。
10. 当前工程只证明规范的一致性和因果性，性能门槛留给预注册的隔离闭环原型。
