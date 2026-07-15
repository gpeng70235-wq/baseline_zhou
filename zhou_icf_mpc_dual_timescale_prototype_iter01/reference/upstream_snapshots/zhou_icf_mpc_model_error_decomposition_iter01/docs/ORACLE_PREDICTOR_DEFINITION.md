# Oracle Predictor Definition

所有 oracle 仅离线计算，闭环始终执行 P0 已选择的命令。

| 预测器 | F | alpha | 离散/对象 | 分类 |
|---|---|---|---|---|
| P0 | 原 5 区间 algebraic Fhat，跨两拍冻结 | 原 alpha_d/q | 两拍 Euler、等效 pending/selected 电压 | 实际闭环基线 |
| P1 | 同 P0 Fhat | 1/Ld_actual, 1/Lq_actual | 同 P0 | oracle-alpha 离线干预 |
| P2a | 上一完整周期平均 F，original-alpha gauge | 原 alpha | 两拍冻结 F | 时间因果 oracle |
| P2b | k 时刻 IPMSM 物理漂移 F | 原 alpha | 两拍冻结 F | 当前物理 oracle |
| P2c | 用 i(k+1) 反算当前 pending 周期平均 F，original-alpha gauge | 原 alpha | 两拍冻结 F | **非因果上界** |
| P3a | 上一周期平均 F，按 oracle-alpha gauge 重算 | oracle alpha | 两拍冻结 F | 时间因果联合 oracle |
| P3b | k 时刻 IPMSM 物理漂移 F | oracle alpha | 两拍冻结 F | 当前物理联合 oracle |
| P3c | 当前 pending 周期平均 F，按 oracle-alpha gauge 重算 | oracle alpha | 两拍冻结 F | **非因果联合上界** |
| P4 | k 物理 F；第一拍预测后在 i1 重新计算 F | oracle alpha | 每拍显式 Euler | 刷新局部物理模型 |
| P5 | plant 方程隐含的连续漂移 | actual plant | 逐段命令、同对象 RK4 | 离线对象重放下界 |

## F oracle 公式

```text
F_prev^(alpha)(k-1) = [i(k)-i(k-1)]/Ts - alpha .* u_applied_eq(k-1)
F_inst(k) = f_IPMSM(i(k), omega(k), Rs_actual, Ld_actual, Lq_actual, psi_actual)
F_current^(alpha)(k) = [i(k+1)-i(k)]/Ts - alpha .* u_pending_eq(k)
```

P2a/P3a 分别在 original/oracle alpha 的 gauge 下重算上一周期平均 F；P2c/P3c 同理在各自 alpha 下重算当前周期平均 F。P3a/P3c 不直接把 original-gauge F 和 oracle alpha 拼接为主要证据；`*_fixed_gauge` 字段只审计这种混搭会产生的差异。

## gauge 不可辨识性

从输入输出数据单独观察 `di/dt = F + alpha*u` 时，任取 `delta_alpha`，令 `alpha' = alpha + delta_alpha`、`F' = F - delta_alpha*u`，在该输入点可以保持同一斜率。因此“F 误差”和“alpha 误差”不是无条件可辨识的物理量。本文注册一个 canonical gauge：alpha oracle 固定为真实 `1/Ld,1/Lq`，F_inst 固定为 IPMSM 无输入漂移项；上一/当前平均 F 必须与所用 alpha 成对反算。F/alpha Shapley 贡献只在该 gauge 和本场景输入覆盖内解释。

## 因果/部署分类

- P0：实际可运行基线。
- P1：公式时间因果，但 oracle alpha 需要真实参数；是离线干预。
- P2a/P3a：只用上一完整周期，时间因果；仍依赖真实对象端点/参数定义，不等于现成 estimator。
- P2b/P3b/P4：不使用未来电流反算，但需要真实 plant 状态和参数，是机理 oracle。
- P2c/P3c：使用 i(k+1)，**非因果、不可部署**，只给当前平均 F 完美时的上界。
- P5：与对象相同的方程、参数、分段命令和 RK4 重放，**不可部署**，仅作记录/对齐下界。
