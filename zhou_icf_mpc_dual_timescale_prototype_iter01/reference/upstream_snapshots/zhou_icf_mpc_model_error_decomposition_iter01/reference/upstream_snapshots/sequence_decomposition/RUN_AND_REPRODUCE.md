# 运行与复现

## 1. 环境与入口

- 已登记 MATLAB 版本：R2024b。
- 工程：`C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_sequence_decomposition_iter01`
- 唯一总入口：`run_sequence_decomposition.m`
- 随机种子、采样周期、积分步长、场景及约束均由 `config/` 固定。

建议从一个新的 MATLAB 会话开始：

```matlab
cd('C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_sequence_decomposition_iter01')
outcome = run_sequence_decomposition('all');
```

入口固定先执行：

```matlab
restoredefaultpath
rehash toolboxcache
clear classes
clear functions
clear mex
close all
clc
```

随后只加入本工程根目录、`config/`、`src/`、`audit/` 与 `tests/`。不得先手工 `addpath(genpath(...baseline_zhou...))`。

## 2. 模式

```matlab
run_sequence_decomposition()             % 等价于 'all'
run_sequence_decomposition('all')        % 盘点、基线、正式诊断、冻结复核；不运行原型
run_sequence_decomposition('inventory')  % 上游/复制来源/防重复检查
run_sequence_decomposition('baseline')   % 最小冻结基线门
run_sequence_decomposition('audit')      % 三层预测、分解、离线候选一致性与汇总
run_sequence_decomposition('prototype')  % 人工调用且受硬门控制
```

不要用 `audit` 绕过首次正式运行的 baseline gate。可重复开发时单独调用模式，但正式 A–E 结论应来自完成全部门控的 `all` 运行。

## 3. 预运行检查

1. 确认四个绝对路径均存在，证据文件与 `SOURCE_PROJECTS.csv` 一致。
2. 确认 `SOURCE_SHA256_BEFORE.csv` 已覆盖四个上游的逐文件哈希。
3. 检查 `COPIED_FILE_PROVENANCE.csv`；复制到本工程的冻结代码必须字节一致。
4. 确认 `Jd_limit_A2` 与 `Jq_limit_A2` 都为 `0.16`。
5. 运行路径审计，关键函数的 `which -all` 结果只能落在本工程或 MATLAB 自带目录。
6. 确认没有请求 608 点扫描或 E1/E2 重建。

任何上游 SHA、约束值或关键函数解析异常都应停止后续阶段，不能自动“修复”。

## 4. 最小基线门

正式诊断前至少核验：IPMSM 标称工况、`Ld=Lq` 退化、负 `id`、独立 `alpha_d/alpha_q`、S2 不触发、已知 S2 边界触发、代表性 false-safe、THD 有效性、三次重复确定性、上游 SHA 不变。基线结果由 `docs/BASELINE_REPRODUCTION_REPORT.md` 和 `results/summary/baseline_comparison.csv` 记录。

冻结约束：

```text
Jd_limit = 0.16 A^2
Jq_limit = 0.16 A^2
```

## 5. 审计数据对齐

对每个可对齐样本，必须保存 `prediction_index=k`、`selected_index=k`、`applied_index=k+1`、`actual_index=k+2`。从闭环状态 `i(k)` 出发做两周期重放：先重放周期 k 正在 pending/applied 的最终序列，再重放周期 k 选出、在 k+1 施加的最终序列。

`i_actual(k+2)`只能读取闭环轨迹。离线重放值不得写回控制器，也不得冒充实际值。最后两个无 `k+2` 观测的样本必须标为不可对齐并从分解统计中排除，不可填零、外推或复制末值。

## 6. 输出核验

正式运行后至少检查：

- `results/raw/sample_decomposition.csv` 含三层预测、实际值、两套残差分解、时序、最终序列及 S2 标志。
- `results/summary/` 含 case、残差、混淆矩阵、序列模式、离线候选及重复性汇总。
- 两套恒等闭合误差都在预注册浮点容差内。
- 候选 top-1/top-3 清楚标为离线诊断候选库，不声称是原控制器原生候选。
- `results/figures/` 的图由正式 CSV 生成，不使用手填常量。
- `SOURCE_SHA256_AFTER.csv` 与 before 对比，上游变化数必须为 0。
- `docs/DECISION_AND_NEXT_STEP.md` 只能给出一个 A–E 结论；若恒等式或时序门失败只能给 E。

## 7. 三次重复

重复性运行必须使用相同配置与随机种子。比较逐样本关键字段和所有聚合指标，并把结果写入 `results/summary/repeatability_check.csv`。若实现允许不同 `run_id`，应保留各次运行目录；不得覆盖唯一一份正式原始轨迹后再声称可重复。

## 8. 增加新工况

只在最小代表集无法区分误差来源时增加定向工况：

1. 在 `config/sequence_scenarios.m` 新增唯一 `case_id`。
2. 标注 `case_category` 以及 `normal`、`reasonable_extension` 或 `stress_test`。
3. 说明新增工况要区分的假设，避免无控制的笛卡尔积扫描。
4. 参数偏差绝对值达到或超过 30% 时必须标为压力测试。
5. 不改变既有工况或删除失败轨迹；若变更配置，创建新 run_id 并记录到 `CHANGELOG.md`。

## 9. 原型门

`prototype` 不是复现正式诊断的必需步骤。只有结论 A 或 C，并且至少三个合理工况存在重大 false-safe、逐段预测使其相对下降至少 50%、排序或可行性稳定翻转、问题不依赖极端压力点、计算时间有实现可能且三次重复一致时，才允许人工调用。结论 B、D 或 E 时必须拒绝原型。

## 10. 交接前封存

保存正式 run_id、MATLAB 版本、配置哈希、关键 CSV、图及报告；执行 after 哈希；确认冻结上游变化数为 0。任何仍为 `[待正式运行写入]` 的结果字段都必须在交接说明中标为未完成，不能用推测数值替代。
