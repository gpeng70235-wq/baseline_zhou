# Path Conflict Report

目标目录在执行前不存在，现位于研究根目录的独立同层工程，不嵌套进任何上游。工作区 Git 原有未跟踪 `paper/` 与 `zhou_icf_mpc_reproduction_iter11/` 均未修改。

六个冻结路径：

1. `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_model_error_decomposition_iter01`
2. `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_sequence_decomposition_iter01`
3. `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_feasibility_control_iter01`
4. `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_probe_iter01`
5. `C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_robust_constraint_iter01`
6. `C:\Users\catkin\Documents\baseline_zhou\baseline_zhou-main\baseline_zhou-main\zhou_icf_mpc_constraint_audit_v1`

第 6 项存在嵌套同名根，已选择指定名称的实际目录。盘点时 model-error 有 256 个文件、probe 有 132 个文件；sequence、feasibility、robust 和 constraint-v1 四个指定路径只含空子目录，标记为 `FOUND_EMPTY_STUB`。其历史报告/代码只在 populated model-error 工程的既有 frozen snapshots 中读取。另发现 `zhou_constraint_consistency_audit_iter01`，名称和目标证据链不同，未冒充指定的 v1。

八篇 canonical PDF 均选自 `baseline_zhou\paper`；Downloads 中发现 P04/P06/P07 标题副本，但没有复制或混用。PDF index 的 SHA 固定 canonical copy。

MATLAB 入口只 `addpath(target/src)`，不 `genpath` 任何上游。所有引用上游文件均是 hash-equal snapshot，来源见 provenance CSV。
