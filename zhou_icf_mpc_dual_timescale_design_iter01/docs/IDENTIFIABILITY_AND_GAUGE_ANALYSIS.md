# Identifiability and Gauge Analysis

## 原问题

单个样本只给出 `y=F+alpha*u`。若 F 可逐样本任意变化，则对任意 `delta`，`alpha'=alpha+delta` 与 `F'=F-delta*u` 产生相同 y；F-alpha gauge 不可辨识。直接让 F 与 alpha 以相同带宽自由更新会把噪声、耦合或受限电压误差在两者间任意搬移。

## 本设计降低耦合的方法

1. 带宽正交：F 每拍低通跟踪；alpha 只每 20 拍从 `u_hp/y_hp` 相关性更新。
2. gauge 顺序固定：先得到 posterior alpha，再用同一 alpha 形成 `F_meas=y-alpha*u_app`，禁止混合 old-alpha F 与 new-alpha。
3. 激励门控：幅值、窗口能量、归一化 regressor conditioning、零矢量停滞和 residual jump 同时检查。
4. 实际输入：S2 后实际 segment-equivalent 电压避免把 voltage clipping 误吸收到 alpha/F。
5. 有界性：alpha 投影到 nominal-controller commissioning envelope；无激励时保持上一值。
6. 轴独立：d/q 状态、窗口、投影与冻结原因分开，耦合残差由各自 F 吸收。

这些约束缩小了可行 gauge 集，但没有数学上消灭 gauge。以下假设必须成立：alpha 在慢窗口内近似常数；F 的主要能量低于 alpha 识别频带；`F_hp` 与 `u_hp` 不显著相关；实际电压重构准确；采样时序与角度一致；差分噪声没有主导 y_hp。

## 可辨识与不可辨识区

长期零矢量、稳态低变化、低速近零输入或强电压饱和但缺少最终时长日志时，alpha 不可辨识并冻结。F 只有在 `u_app` 可信时更新。d/q 磁耦合若在 alpha 频带与输入相关，会污染独立标量 alpha；原型必须记录 cross-correlation，而不是提前加入矩阵 alpha。

## 可证伪条件

- `corr(u_hp,F_residual_hp)` 在 gate-on 窗口持续显著；
- alpha 经常贴投影边界或 d/q 同时同向漂移；
- good excitation 下 alpha 更新提高 RMS/false-alarm；
- S2 触发窗口的重构闭合误差超过电压容差；
- 量化/噪声使 y_hp 方差远高于控制激励；
- 合理工况超过 500 拍不能获得三个连续 good windows。

满足任一项应回退到 B 结论并停止闭环扩展。原型必须记录 alpha/F、投影、各 gate、freeze reason、u_app reconstruction residual、窗口能量/conditioning、y_hp/u_hp、decision margin、false-safe/false-alarm 和 mode flip。
