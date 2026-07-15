# Frozen Evidence Base

实际使用的完整 B0 数据来自 archived dual-timescale prototype 内、Git commit `2aa4e7f` 恢复的 model-error snapshot：`reference/upstream_snapshots/zhou_icf_mpc_model_error_decomposition_iter01/results/raw/model_error_samples.csv`。
本工程在分析前将其字节级复制到 `reference/frozen_data/model_error_samples.csv`；另复制 prototype 的五工况 `closed_loop_samples_B0.csv` 做 4,821 行点对点独立重现交叉检查。未重新运行 B0。

冻结事实：原主域 false-safe 3.029664%，全量 3.059661%；sequence 误差约 1e-13；plant oracle 可零误差重放；F/alpha 离线 oracle 有效但 causal dual-timescale online prototype 失败；P 的五工况 false-safe 3.526239%→3.753128%，向量 RMS 0.0613189 A→0.132352 A；B1/B2/RLS 未过门禁。

完整来源、解析路径和逐文件 SHA-256 位于 `audit/`。所有复制文件均在 `COPIED_FILE_PROVENANCE.csv` 记录双端哈希。
