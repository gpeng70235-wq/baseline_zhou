# Dual-Timescale Algorithm Specification

## 1. 模型与状态记法

对 `x in {d,q}` 独立建模：

```text
di_x/dt = F_x + alpha_x u_x
```

`alpha_d` 与 `alpha_q` 是两个不同状态、不同初值和不同投影区间；禁止共享标量或内存。进入行 k 的先验记为 `alpha_x^-(k)=alpha_x^+(k-1)`，本行因果数据更新后的后验记为 `alpha_x^+(k)`。F 同理。数值偶然接近不是公共状态；诊断必须验证轴内存无别名。

## 2. 因果观测与频带分离

```text
y_x(k) = [i_x(k)-i_x(k-1)]/Ts
u_x(k) = u_app_eq_x(k-1)

u_bar_x(k) = u_bar_x(k-1) + beta_u_x [u_x(k)-u_bar_x(k-1)]
y_bar_x(k) = y_bar_x(k-1) + beta_y_x [y_x(k)-y_bar_x(k-1)]
u_hp_x(k) = u_x(k)-u_bar_x(k)
y_hp_x(k) = y_x(k)-y_bar_x(k)
```

这里只有当前/过去电流和已完成执行区间；没有 `i(k+1)`。低频 F、耦合、参数偏差和反电势主要进入低通/快速 F 通道；alpha 仅从慢窗口内的高频相关性更新。

## 3. 慢 alpha 更新

当 `g_alpha_x(k)=g_exc_x & g_s2 & slow_tick`：

```text
e_alpha_x(k) = y_hp_x(k)-alpha_x^-(k) u_hp_x(k)
alpha_raw_x(k) = alpha_x^-(k)
  + s_s2(k) gamma_alpha_x u_hp_x(k)e_alpha_x(k)
    / [epsilon_alpha_x+u_hp_x(k)^2]
alpha_x^+(k) = Projection(alpha_raw_x(k), alpha_min_x, alpha_max_x)
```

否则 `alpha_x^+(k)=alpha_x^-(k)`。默认 `N_alpha=20`，即 2 ms 更新一次；高电压利用率时 `s_s2=0.25`，正常为 1。初值 `[1250;833.333333] A/(V·s)` 来自冻结 Zhou controller configuration，不是实际 Ld/Lq。上下界是各自初值的 `[0.5,1.5]` commissioning envelope，原型变更须重新预注册，不能由真实电感在线注入。

## 4. 快 F 更新与协调

使用同一行 posterior alpha：

```text
F_meas_x(k) = y_x(k)-alpha_x^+(k) u_app_eq_x(k-1)
F_x^+(k) = F_x^-(k) + g_F_x beta_F_x [F_meas_x(k)-F_x^-(k)]
```

真实执行电压可信且历史有效时 F 每拍更新；alpha 因激励、慢 tick 或 residual-jump 冻结时仍允许 F 更新。若执行电压不能确认，则 `F_meas` 无定义，F 与 alpha 均冻结。F 限幅仅为异常保护 `[−5e5,5e5] A/s`，不能当作正常饱和控制。

## 5. 决策敏感区趋势

```text
F_pred_x(k) = F_x^+(k)
  + g_decision_latched(k) rho_F_x [F_x^+(k)-F_x^+(k-1)]
```

当前原生选择完成后计算 `m_J=min(Jd_limit-Jd_pred,Jq_limit-Jq_pred)`；当 `0<=m_J<=delta_J` 或原生模式 gap 小于阈值时，锁存下一拍 gate。趋势只改变预测器使用的 F，不修改 Jd/Jq 阈值、候选集合、模式或 S2。

## 6. 精确两拍预测

```text
i_hat(k+1|k) = i(k) + Ts [F_pred(k)+alpha^+(k).*u_pending_eq(k)]
i_hat(k+2|k) = i_hat(k+1|k)
                 + Ts [F_pred(k)+alpha^+(k).*u_selected_final_eq(k)]
```

第一拍 pending 已提交；第二拍电压必须是 S2 后最终 selected 的 segment-midpoint 等效值。两个步长均为 Ts，不以 2Ts 一步近似。

## 7. 参数与风险

默认参数见 `design.project_parameter`。d/q 参数以向量独立保存；当前 beta/gamma 数值相同只是初始预注册，不代表共享状态，原型允许按轴调参但不得跨组临时改变。电流差分会把测量噪声放大约 `1/Ts=10,000 s^-1`；因此 alpha 依赖慢 tick、能量/条件门控、epsilon 和 residual-jump。若实际 `F_hp` 与 `u_hp` 相关，高频正交化仍会有偏，必须由原型诊断否证。
