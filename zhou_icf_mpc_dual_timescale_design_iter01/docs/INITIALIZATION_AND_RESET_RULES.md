# Initialization and Reset Rules

启动时使用冻结 Zhou controller 的 `alpha_d=1250`、`alpha_q=833.333333 A/(V·s)`，不是 plant 电感倒数；F 与 trend 为零。首个可信 current/voltage pair 只初始化 `u_bar/y_bar` 和历史，不更新 alpha。达到完整 20 点窗口、历史有效且三个门控通过后，alpha 才可首次更新。

硬复位条件：采样周期变化；sample index 逆跳；任一状态 NaN/Inf；Vdc/矢量表改变但接口未重新配置；执行段总时长不闭合持续出现；用户显式 reset。硬复位清空 F、滤波/窗口/锁存，alpha 回到 controller initial，`history_valid=false`。

软冻结条件：激励不足、非 slow tick、零矢量停滞、regressor ill-conditioned、residual jump、高利用率但仍可重构。软冻结保留 alpha；实际电压可信时 F 继续。若执行电压不可信，F 也保留。

长期冻结超过 500 拍时进入 reacquire：继续只记录窗口；获得 3 个连续 good windows 后才重启 alpha；首个重启窗口用 0.25 步长。任何 good-window 中断将计数归零。

`design.project_parameter('reset')` 是断开的参考 reset 输出。复位不得改写 Zhou、Jd/Jq、mode、candidate 或 S2 状态。
