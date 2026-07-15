# Zhou ICF-MPC S2-Aware Dual-Timescale Predictor Design

这是一个完全隔离、可审计、可交接的算法设计工程。它把冻结 P0-P5 归因与八篇论文机制固化为一条主设计：轴独立、双时间尺度、激励门控、S2 实际执行电压反馈、原生决策敏感区增强的一阶超局部预测器。

结论为 **A：设计通过，可进入隔离闭环原型**。这只授权下一独立工程按预注册方案验证，不代表性能已证明；本工程没有修改/调用 Zhou 控制器、S2、Jd/Jq、模式或候选逻辑，也没有运行 24 工况。

核心设计：alpha_d/q 是慢速、有界、逐轴、每 20 拍且仅在 excitation/S2 gates 通过时更新；F_d/q 用 posterior alpha 和 `u_app_eq(k-1)` 每个可信采样快速更新；当前原生决策的 margin/gap 锁存为下一拍 trend gate。预测严格为 pending(k) 的 k+1 步和 post-S2 selected(k) 的 k+2 步。

运行：

```matlab
run_dual_timescale_design()
run_dual_timescale_design('inventory')
run_dual_timescale_design('literature')
run_dual_timescale_design('timing')
run_dual_timescale_design('design')
run_dual_timescale_design('audit')
run_dual_timescale_design('all')
```

无参数等价于 `all`。完整复现与环境见 `RUN_AND_REPRODUCE.md`，算法见 `docs/DUAL_TIMESCALE_ALGORITHM_SPEC.md`，正式交接见 `HANDOFF.md`。

审计摘要：6 个指定路径全部找到，其中 2 个 populated、4 个为当前 empty stub；388 个可见上游文件全部逐文件 SHA256。8/8 PDF；15 个必要证据/代码 snapshot 均与源哈希一致。空壳上游的历史证据只从已冻结在 model-error 工程内的 snapshot 读取，不把空目录误报为完整工程。最终变更数以 `audit/FROZEN_UPSTREAM_VALIDATION.csv` 为准。
