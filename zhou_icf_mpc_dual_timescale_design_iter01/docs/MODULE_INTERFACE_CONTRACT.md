# Module Interface Contract

所有数值默认 IEEE-754 double 参考类型；DSP 类型在原型中另行固定。时间索引均以控制行 k 为准。本工程中的 `closed-loop` 全为 **否**。

| 模块 | 输入（单位/索引） | 输出 | 状态 | 更新/冻结/异常 | closed-loop |
|---|---|---|---|---|---:|
| `dual_timescale_predictor` | i(k) A；pending_eq(k), selected_final_eq(k) V；posterior F A/s、alpha A/(V·s) | i_hat(k+1|k), i_hat(k+2|k) A | 无 | 输入非有限即拒绝；不降级使用目标电压 | 否 |
| `fast_F_estimator` | y(k) A/s；u_app(k-1) V；alpha_post(k) | F_post, F_pred A/s | F(k-1),F(k-2) | u_app 可信则每拍；不可信冻结；越界限幅并报 fault | 否 |
| `slow_alpha_estimator` | u_hp/y_hp；gates；slow tick | alpha_post A/(V·s) | alpha d/q | 每 20 拍且 gate 全真；否则保持；硬投影 | 否 |
| `excitation_gate` | u_hp V；窗口能量 V²；normalized rcond；零矢量 run；residual jump A/s | per-axis g_exc 与原因 | rolling sums/run counters | 数据缺失置 false；连续 good windows 后复活 | 否 |
| `s2_input_quality_gate` | final IDs/durations/Vdc/theta/omega；S2 flag；utilization | g_s2, step scale, reconstruction status | 最近有效电压与故障计数 | S2 flag 本身不冻结；未知裁剪/缺日志冻结 | 否 |
| `decision_margin_gate` | native Jd/Jq 与 limits A²；native mode gap A² | g_decision_next | one-cycle latch | 非原生/非有限输入置 false；不读 offline bank | 否 |
| `estimator_state_reset` | reset reason；current sample；last trusted u | initialized state | 全部估计状态 | startup、timebase jump、NaN、长期 invalid voltage 时复位 | 否 |
| `estimator_diagnostics` | all states/gates/residuals | log row and fault bits | counters/maxima | 日志失败不得偷偷使用 target voltage；冻结 alpha | 否 |

边界来自 `design.project_parameter`：alpha 逐轴 `[0.5,1.5] * alpha_initial`；F 绝对值不超过 `5e5 A/s`；duration tolerance `1e-12 s`。初始化和复位见专文。

下一原型允许用适配层把这些接口连接到 Zhou，但必须保持原函数不可修改，并把 post-S2 final command 的执行日志作为唯一 estimator voltage source。
