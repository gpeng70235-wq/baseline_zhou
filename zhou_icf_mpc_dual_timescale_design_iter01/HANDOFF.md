# Handoff

## 1. 项目目标

为 Zhou ICF-MPC 设计一个不改动原约束决策和 S2 的、可部署候选 predictor 规范：逐轴 alpha 慢适应、F 快适应、实际执行电压反馈与决策边界趋势增强。当前仅设计/测试，不闭环。

## 2. 当前研究链与冻结上游

研究链：constraint/probe/feasibility/robust audits → sequence decomposition → model-error decomposition → 本 dual-timescale design。六个实际绝对路径列在 `audit/SOURCE_PROJECTS.csv`；其中 constraint audit v1 位于 `baseline_zhou-main\baseline_zhou-main` 嵌套目录。盘点时 model-error/probe 分别有 256/132 个文件，另外四个指定路径是 empty stub；其历史证据只从 model-error 已冻结 snapshot 读取。before 快照含 388 个实际可见文件。

## 3. 已排除 sequence 路线

冻结 sequence/total 约 `1.02737154281e-13`，仅浮点量级。不得再研究执行顺序、重跑序列分解或用 sequence 解释主 false-safe。

## 4. P0-P5 归因

P0 全量 false-safe 3.059661%，工程主域 3.029664%；P3b 0.807353%；P4 0.679005%；P5 0。F/alpha/structure 份额 53.88%/28.66%/17.46%。P1/P2b 虽降 false-safe，却将 RMS 推至约 0.313/0.312 A 且 false-alarm 约 16.59%/17.34%。P3a/P3b 的一致联合替换优于单换。P2b/P3b/P4/P5 均是 oracle/诊断，不是部署算法。

## 5. 八篇论文的统一机制

不是八个并列方案：统一为实际 input-output 数据对 → 慢有界 input gain → 快 lumped dynamics → excitation/voltage quality freeze → regularization/projection → causal delay compensation。完整 RLS/ESO/AULTS/immune/harmonic 结构不复制。8/8 PDF、DOI、SHA、公式和机制见 `references`。

## 6. 最终主设计

`di_d/dt=F_d+alpha_d u_d`、`di_q/dt=F_q+alpha_q u_q`。两个轴是独立状态。alpha 表示输入通道增益，F 吸收低频集总动态、耦合、参数偏差和未建模项。alpha 每 20 拍门控更新；F 每个可信采样更新；near-decision trend 只作用 predictor。

## 7. 为什么不直接用完整 RLS/ESO/AULTS

完整 RLS/AULTS 引入 covariance、变阶或 PSO；ESO/AGESO 增加 observer 状态和 bandwidth 调参；immune/谐波补偿引入启发式或与冻结证据不相称的结构。它们会扩大计算、辨识和交接风险，且不是 Zhou decision/S2 机制。仅保留二参数 constrained RLS 作为下一原型上限对照。

## 8. Gauge 问题与处理

`y=F+alpha*u` 对 sample-wise F 不可辨识。处理是频带分离、不同时间尺度、先 alpha 后同-gauge F、actual voltage、excitation/conditioning gate、projection 和 freeze。它降低但不消除 gauge；`corr(u_hp,F_residual_hp)` 等已注册为可证伪量。

## 9. k/k+1/k+2

row k 采样 i(k)；pending(k) 在 k→k+1 执行；第一步预测 `i_hat(k+1|k)`；Zhou 原生几何选 mode/command；S2 得 final selected(k)；第二步预测 `i_hat(k+2|k)`；Jd/Jq 对 ref(k)。两步各 Ts。`selected_final(k)=applied(k+1)`。

## 10. selected/pending/applied 定义

`selected_core(k)` 是原生 Zhou 当前行结果；`selected_final(k)` 是 S2 后排队命令；`pending(k)=selected_final(k-1)`，也是 row k 的 `applied_sequence(k)`；`u_app(k-1)` 是刚完成 k-1→k 区间的最终等效电压。

## 11. S2 实际执行电压接口

由最终矢量 ID、每段时长、实际 Vdc、theta/omega 和 segment midpoint 重构 `sum(tau/Ts)*Park(v_ab,theta_mid)`。S2 trigger 本身不冻结；非法时长、未知裁剪、缺日志或 reconstruction failure 冻结。禁止使用 pre-S2 target/reference voltage。

## 12. Alpha 公式

`e=y_hp-alpha_prior*u_hp`；`alpha_raw=alpha_prior+s_s2*gamma*u_hp*e/(epsilon+u_hp^2)`；`alpha_post=Projection(alpha_raw,min,max)`。默认每 20 拍，初值 1250/833.333333，逐轴 bounds 为 initial 的 0.5-1.5 倍；不读真实 Ld/Lq。

## 13. F 公式

`F_meas=y-alpha_post*u_app(k-1)`；`F_post=F_prior+g_F*beta_F*(F_meas-F_prior)`；`F_pred=F_post+g_decision_latched*rho*(F_post-F_previous)`。只有 actual voltage 可信才更新。

## 14. 三个 gates

excitation：hp 幅值、窗口能量、normalized regressor rcond、零矢量 run、residual jump；S2 quality：final command 可重构及高利用率降步长；decision：原生 Jd/Jq margin 或 native mode gap，当前行锁存、下一行使用。truth table 已固化。

## 15. d/q 独立

状态、初值、bounds、窗口、mask、freeze reason 全部逐轴；没有公共 alpha。当前 gamma/beta 初值相同只是配置值，不共享内存。单元测试证明单轴更新不覆盖另一轴。

## 16. 初始化与 reset

startup 使用 controller alpha、F=0、history invalid；完整窗口后才 alpha update。timebase jump、NaN、Vdc/vector reconfiguration 或持续时长不闭合硬 reset；长期冻结三 good windows 后以 0.25 step reacquire。

## 17. 计算预算

最坏两轴 slow tick：40 add/sub、26 multiply、4 divide、20 compare、2 projection；平均摊销约 34.3/18.4/2.1/16.2/0.1。无 matrix inverse。MATLAB reference timing 由入口生成；DSP 相对 B0 <=25% 是 prototype 硬门。

## 18. 单元测试

十个测试文件覆盖维度、无未来数据、projection、excitation freeze、S2 actual voltage、decision latch、reset、axis independence、determinism、path isolation。最终通过/失败数写入最终交付说明和 `results/summary/test_summary.csv`。

## 19. 最终 A-E 结论

**A：设计通过，可进入隔离闭环原型。** A 只表示接口/公式/时序/因果/预算设计成立；性能未在本工程证明。若 actual segment log 不可得或 high-pass identifiability 被否证，降为 C/B。

## 20. 下一工程名

`zhou_icf_mpc_dual_timescale_prototype_iter01`，当前未创建。

## 21. 下一对照组

B0、B1、B2、P、RLS，定义见 preregistration；禁止添加其他组。

## 22. 下一生死门槛

主域 false-safe 相对下降 >=50% 且 <=约1.52%；false-alarm <=2%；RMS <=110% B0；THD/torque 各恶化 <=5%；跨 cohort 重复；DSP <=25%；无 oracle/future；S2 稳定；三次确定。

## 23. 冻结绝对路径

见 `audit/SOURCE_PROJECTS.csv` 和 `docs/PATH_CONFLICT_REPORT.md`，不要手工猜测同层路径。

## 24. SHA256

before/after 是逐文件表；validation 记录 added/removed/changed。15 个复制件全部 `hash_match=true`。最终上游变化数必须为 0，否则 A 自动失效。

## 25. 已知限制与禁止事项

主要限制是残余 gauge、差分噪声、上一拍 decision latch、hardware applied-log 可用性和 DSP baseline 未实测。仍禁止修改闭环、S2、J limits、modes、candidates；禁止真实 Ld/Lq、future current、oracle P2b/P3b/P4/P5、谐振器和自动进入 prototype。
