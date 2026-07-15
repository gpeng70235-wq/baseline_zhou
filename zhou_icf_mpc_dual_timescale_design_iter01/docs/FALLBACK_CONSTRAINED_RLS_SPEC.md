# Fallback Constrained RLS Specification

备用仅用于下一原型性能上限对照，不是当前主路线。逐轴回归：

```text
y_x(k) = [1, u_app_x(k-1)] theta_x(k) + e_x(k)
theta_x = [F_x, alpha_x]'
K = P phi / [lambda + phi' P phi]
theta_raw = theta + K [y-phi' theta]
alpha = Projection(theta_raw(2), alpha_min, alpha_max)
F = clip((1-mu_F) theta_raw(1), -F_max, F_max)
P = lambda^-1 [I-K phi'] P
```

`lambda` 预注册范围 `[0.98,0.9995]`；P 初值必须对角正定并加 `delta I` 正则。激励不足时设置 `K_alpha=0`，只允许带正则的 F 列更新；连续零矢量超过 3 拍冻结 alpha 列。任何时刻禁止 F/alpha 无投影同时漂移。

输入仍必须是 post-S2 `u_app(k-1)`，不能使用目标电压、真实 Ld/Lq 或未来电流。该 2x2 covariance 更新每轴约 20 乘法、18 加减、1 除法，显著高于主路线；只命名为 `RLS` 对照，不实现完整 Brosch AFW/DFW、Wei extended-affine/AULTS。
