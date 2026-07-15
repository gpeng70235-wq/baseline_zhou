# Exact Timing and Signal Map

## 冻结实现事实

控制行 k 开始时采样 `i(k), theta(k), omega(k)`。`pending(k)` 是行 k 开始前已提交的最终命令，即 post-S2 `selected(k-1)`；它在 `k→k+1` 执行。核心 Zhou 先以 pending 等效电压得到 `i_hat(k+1|k)`，再由 `ref(k)`、第一拍预测、F 和 alpha 构造独立 Jd/Jq 矩形；几何分析完成单/双/三矢量模式选择。随后 S2 只可能替换非法原生 Case 3，产生最终 `selected_final(k)`，该命令在 `k+1→k+2` 执行。最终 Jd/Jq 由 `ref(k)` 与 `i_hat(k+2|k)` 计算。

因此：

- `selected(k)=applied_sequence(k+1)`；
- `pending(k)=applied_sequence(k)=selected_final(k-1)`；
- 更新器在行 k 使用刚完成区间 `k-1→k` 的 `u_app_eq(k-1)`；
- `F_post(k)` 与允许时的 `alpha_post(k)` 均在预测前计算；
- 两个预测步各为一个 Ts，`i_base=i(k)`，不存在自行选择 Ts/2Ts；总预测跨度是两拍。

原 Fhat 是截至 k 的 5 个完整电压区间 Fliess-Join algebraic integral（6 个电流端点），然后跨两拍冻结。新设计替换点只在下一原型中作为 predictor state provider；本工程不接入。

## 实际电压重构

对一个实际执行命令的第 j 段，令矢量 ID 为 `n_j`、时长为 `tau_j`、段起点为 `s_j=sum_{l<j} tau_l`，则

```text
theta_j = mod(theta_sample + omega_e*(d*Ts + s_j + tau_j/2), 2*pi)
u_app_eq_dq = sum_j (tau_j/Ts) * Park(v_ab[n_j], theta_j)
```

pending 预测用 `d=0`；本行 selected 的未来执行用 `d=1`。估计器的 `u_app(k-1)`必须来自实际完成命令的矢量 ID、最终作用时间、实际 Vdc/矢量表以及同一段中点角规则。目标 `reference_ab`、S2 前命令、被裁剪时长或仅占空比请求值均不是合法替代。

## 采样、计算与 PWM 延迟

冻结实现存在一拍命令队列：行 k 计算的命令不能在 `k→k+1` 立即执行，而在 `k+1→k+2` 执行。软件 plant 在行末完整积分当前 pending 命令。该队列语义与冻结 `selected(k)=applied(k+1)` 逐命令、逐时长断言一致。

## 决策门控索引

为避免 `g_decision` 与同拍预测/选择构成代数环，行 k 原生 Zhou 选择的 Jd/Jq 裕度和模式 gap 只生成 `g_decision_next(k)`；行 k+1 的预测器消费该锁存值。它仍来自“当前原生选择结果”，但趋势影响下一拍。若原型要求同拍二次求值，计算量和逻辑会改变，当前规范禁止。
