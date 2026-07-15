# Duplicate Work Check

## 结论

**未发现上游已经完整实现本项目。允许且已经完成新增开发。**

## 检查范围

检查五个上游的 README/HANDOFF/正式报告、sequence 的 sample/candidate/residual CSV、robust residual 数据定义、S2 报告、场景配置和复制到 `reference/upstream_snapshots` 的证据。BEFORE 快照覆盖 `2214` 个文件。

## 已存在但不重复的内容

- k/k+1/k+2、selected(k)=applied(k+1)、电角度和两周期命令对齐已有先验，本工程把它们作为断言复核。
- average vs piecewise frozen-F ultralocal 的 sequence 项已证明为 `1.02737154281e-13` 量级，本工程不再把它列为误差源。
- plant oracle 曾证明可复现 actual；本工程 P5 只作为每个新样本的对齐下界再次断言。
- 旧 24 场景定义可复用，但 P0--P5 字段必须本地重新生成。

## 上游缺口

上游没有同时提供：P1 oracle alpha、P2a/b/c 三类 F、P3a/b/c 匹配 gauge 的联合替换、P4 刷新物理斜率、逐级 MSE/Shapley 归因、同一诊断候选 bank 的 P0--P5 重排，以及基于这些量的 A--F 门禁。因此本工程不是 sequence_decomposition_iter01 的复制。

## 防回退门禁

若未来上游出现同版本、同公式、同样本键、同汇总和同决定表的完整 P0--P5 工程，应停止再次实现，只做逐字节与数值复核。当前本地输出结论为 `C`，对应本工程首次注册的内部归因。
