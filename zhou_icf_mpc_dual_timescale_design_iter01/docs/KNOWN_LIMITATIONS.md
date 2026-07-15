# Known Limitations

- 高频正交化只降低而不消除 F-alpha gauge；`F_hp` 与 `u_hp` 相关时 alpha 有偏。
- 当前 bounds 是 controller-initial commissioning envelope，尚未由硬件安全分析缩紧；绝不等于真实 Ld/Lq 范围。
- 差分电流在 100 us 下放大传感/量化噪声；未在本工程加入滤波器或 observer。
- decision trend 使用上一行锁存的原生边界；快速单拍边界穿越可能错过增强，这是避免循环依赖的明确代价。
- S2/PWM 实机若不记录最终矢量、时长、Vdc 和角度，actual voltage interface 会阻塞；不得用目标值填补。
- d/q coupling 由 F 吸收的频带假设尚待 prototype 否证；当前不升级为矩阵 alpha。
- 理论操作数已给出，但 frozen B0 没有同口径 DSP cycle baseline；25% 只能在预注册 prototype 判定。
- MATLAB reference timing 不是实时 WCET。
- 本工程没有证明 false-safe、RMS、false-alarm、THD 或 torque 改善，且明确禁止当前运行这些闭环实验。
- 6ωe/12ωe 残差没有触发谐振器或 harmonic compensator。
