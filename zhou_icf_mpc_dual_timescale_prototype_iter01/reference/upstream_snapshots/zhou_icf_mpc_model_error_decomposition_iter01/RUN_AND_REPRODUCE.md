# Run and Reproduce

## 环境

已验证环境：`MATLAB 24.2.0.2712019 (R2024b) (2024b)`，Windows。入口会恢复 MATLAB 默认路径，清理 classes/functions/MEX，只添加当前工程的 `config`、`src`、`audit`、`tests`。不要提前把兄弟 Zhou 工程加入 `startup.m`。

## 完整一键运行

```matlab
cd('C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_model_error_decomposition_iter01')
outcome = run_model_error_decomposition();
```

等价显式写法：

```matlab
cd('C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_model_error_decomposition_iter01')
outcome = run_model_error_decomposition('all');
```

`all` 顺序执行 inventory → baseline → audit → frozen-upstream finalization → prototype-disabled gate。它不修改控制器。

## 分阶段命令

```matlab
cd('C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_model_error_decomposition_iter01')
run_model_error_decomposition('inventory'); % 上游盘点、BEFORE SHA、复制来源
run_model_error_decomposition('baseline');  % inventory + 10 项基线
run_model_error_decomposition('audit');     % 需要已经通过 baseline
run_model_error_decomposition('prototype'); % 只记录 BLOCKED_BY_SCOPE
```

## 确定性与 cache

固定随机种子为 `20260715`。每个场景的本地 checkpoint 位于 `results/raw/mat`，只有 `audit_version`、场景 id 和关键字段均匹配时才复用。要强制从零重放，可在确认路径是当前新工程后删除该目录内的 `*_model_error.mat`；绝对不要删除或覆盖上游结果。

## 成功判据

- `results/summary/baseline_comparison.csv` 的 `pass` 全为 1。
- `results/summary/repeatability_check.csv` 的 `pass` 全为 1。
- P0 recompute gap ≤ `2e-10 A`。
- P5 replay gap ≤ `2e-09 A`。
- `FROZEN_UPSTREAM_VALIDATION.csv` 的 `status` 全为 `unchanged`。
- `results/figures/figure_manifest.csv` 的 `generated` 全为 1。

本次完成值：baseline `10/10`，工况 `24`，样本 `24153`，图片 `15/15`，结论 `C`。
