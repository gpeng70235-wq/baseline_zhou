# Literature Mechanism Synthesis

## 统一控制链

八篇文献共同指向一条而非八条路线：采样电流与真实执行电压形成因果数据对；用不同时间尺度拆分输入通道增益和集总动态；在激励、受限电压与噪声条件不满足时冻结慢参数；用投影/正则化限制漂移；把复杂结构留作对照而非直接接入 Zhou。

本设计吸收五个机制：

- extended-affine、AULTS、AGESO 与免疫工作都表明固定 input gain 会污染集总扰动并影响性能，因此 alpha 允许在线变化；但不复制其高阶模型、ESO、PSO 或免疫律。
- RLS 文献明确指出连续零矢量造成秩亏，故 alpha 需要幅值、窗口能量、条件数和零矢量停滞门控。
- self-tuning incremental 文献明确揭示受限目标电压不等于实际电压，故本设计只使用 post-S2 segment-equivalent `u_app`；若不能重构则冻结。
- motor-parameter-free estimation factor 的二次正则化说明慢增益不能逐拍自由漂移，故采用 `N_alpha=20`、归一化梯度和投影。
- 多篇文献的噪声/高频警告要求残差突变门控、更新诊断和高利用率降步长。

## 与已有设计的实质区别

输入增益自适应本身并不新。本设计的独立机制是把它嵌入 Zhou ICF-MPC 的独立 Jd/Jq 决策链：alpha/F 频带分工、S2 后实际电压闭环到估计器、原生决策边界锁存趋势增强，并严格保持候选生成、模式与约束层不变。没有论文同时给出该四者以及 Zhou 的 pending/selected 两拍时序。

## 不照搬的部分

完整 extended-affine RLS、AULTS 变阶/PSO、AESO/AGESO、DFW/AFW 谐波特征、真实电感自调、免疫算法、神经谐波补偿和谐振器均不进入主路线。原因分别是矩阵计算或启发式负担、依赖特定对象结构、引入额外状态/调参，或与本轮 6ωe/12ωe 仅为诊断现象的证据不相称。

逐篇公式、DOI、输入输出、更新量、辨识条件、保护与计算量见 `references/PAPER_MECHANISM_MATRIX.csv`；PDF 绝对路径和 SHA256 见 `references/SOURCE_PDF_INDEX.csv`。
