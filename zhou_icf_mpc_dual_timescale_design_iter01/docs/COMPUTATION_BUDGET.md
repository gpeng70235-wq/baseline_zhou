# Computation Budget

控制周期为 100 us。主路线使用标量/逐轴运算，无矩阵求逆、优化器、指数或三角函数新增；segment Park 变换属于冻结 voltage reconstruction 接口，不能重复计算时应复用 S2/PWM 日志结果。

理论计数见 `results/summary/operation_count.csv`。最坏 alpha 慢 tick、两轴、趋势开启：40 次加减、26 次乘法、4 次除法、20 次比较、2 次投影和约 26 个标量状态。平均摊销（`N_alpha=20`）约 34.3 加减、18.4 乘法、2.1 除法、16.2 比较、0.1 投影。除法包括 normalized gradient 和 conditioning proxy；`1/Ts` 固化为倒数乘法，`1/(epsilon+u_hp^2)` 可在 DSP 用 reciprocal 指令后乘法。

F、滤波和 S2 quality 必须每拍；alpha gradient、投影和 reactivation 仅每 20 拍；文献 PSO/完整 RLS 不进入主路线。decision gate 每拍只做两个 margin、min 与 gap 比较，趋势是每轴一次差、乘、加。

MATLAB 参考时间由 `run_dual_timescale_design('design')` 对断开的两轴 alpha/F 更新循环测量，写入 `results/summary/matlab_reference_timing.csv`。该时间用于回归，不等同 DSP WCET。下一原型必须在目标 DSP 以 cycle counter 分别测 B0 与 P，满足 `(cycles_P-cycles_B0)/cycles_B0 <= 0.25`；否则直接判 E。冻结上游未提供逐操作 B0 基线，因此本设计以“标量计数低风险、DSP 25% 为原型硬门”通过设计预算，不把 MATLAB 比值冒充 WCET 证明。

潜在昂贵操作按优先级：4 个慢 tick reciprocal、segment Park 的 sin/cos（必须复用）、日志搬运。禁止在线高阶 covariance、PSO 或指数函数。
