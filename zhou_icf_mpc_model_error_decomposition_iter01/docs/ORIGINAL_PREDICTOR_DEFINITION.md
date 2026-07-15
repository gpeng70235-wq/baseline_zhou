# Original Predictor Definition (P0)

## 连续模型与离散式

原 Zhou 一阶超局部模型逐轴为 `di_d/dt = F_d + alpha_d u_d`、`di_q/dt = F_q + alpha_q u_q`。在控制行 k：

```text
i_hat(k+1|k) = i_meas(k) + Ts [Fhat(k) + alpha_original .* u_pending_eq(k)]
i_hat(k+2|k) = i_hat(k+1|k) + Ts [Fhat(k) + alpha_original .* u_selected_eq(k)]
Jd = [id_ref(k) - id_hat(k+2|k)]^2
Jq = [iq_ref(k) - iq_hat(k+2|k)]^2
```

`Ts = 0.0001 s`；Fhat 和 alpha 在两次 Euler 更新中均冻结。P0 的本地重算与控制器记录最大差见 `predictor_assertion_audit.csv`，必须 ≤ `2e-10 A`。

## Fhat

Fhat(k) 是 trailing-history 的 Fliess--Join algebraic integral；窗口为 `5` 个完整电压区间（6 个电流端点），电流作分段线性积分、电压作 ZOH。它使用截至 k 的历史，因此是当前行可用的因果估计，但不是简单的“上一周期差分 F”。代码没有额外 IIR 低通。启动时按冻结初值处理，`F_estimator_warmup` 单独标记。

## alpha

原 alpha 来自 controller/paper 参数，两个轴真正独立。本批样本的 `alpha_d_original` 范围为 `1250 .. 1250`，`alpha_q_original` 为 `833.333333333 .. 833.333333333`；真实对象的 `1/Ld_actual`、`1/Lq_actual` 范围分别为 `1041.66666667 .. 1562.5`、`694.444444444 .. 1041.66666667`。原 alpha 不随 plant mismatch 自动改变。

## 电压与角度

P0 不把 S2 输出压成单一静止电压再忽略转角，而是对实际 pending(k) 和最终 selected(k) 命令，按每个执行段的中点电角度变换到 dq 并求周期等效电压。pending 使用 delay=0；selected 使用 delay=1。几何选择使用冻结实现的 execution-segment-midpoint 约定。

## 参数失配位置

参数场景只缩放 plant 的 Ld/Lq；controller 参数仍为冻结 nominal。因此 P06/P07 的“controller high/low”是相对真实对象而言，不是同时修改两侧。Rs、psi、测量噪声、角度误差、dead time 在本轮主归因中不注入。

## 约束拍点

约束用 ref(k) 对比 `k+2|k` 预测。实际标签用同一 ref(k) 对比 trace 的 actual(k+2)。因此 false-safe 不是 k+1 与 k+2 混用。
