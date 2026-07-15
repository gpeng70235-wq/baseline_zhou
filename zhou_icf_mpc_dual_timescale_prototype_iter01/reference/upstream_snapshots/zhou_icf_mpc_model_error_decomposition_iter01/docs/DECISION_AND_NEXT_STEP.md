# Decision and Next Step

## 唯一正式结论

# C — F and alpha jointly dominate

推荐下一路线：**separate compute-bounded extended-affine ultralocal study; independently audit the stable 6x/12x electrical-periodic residual before considering any resonator**。这是下一独立项目建议，本工程不自动实现。

## A--F 门禁

| Gate | Passed | Meaning |
|---|---:|---|
| A | FAIL | F estimation primary |
| B | FAIL | alpha input gain primary |
| C | PASS | F and alpha jointly dominate |
| D | FAIL | freezing/discretization/first-order structure |
| E | FAIL | implementation/timing/metric defect |
| F | FAIL | no engineering-value route under gates |

## 决策量

- 主域注册/公共样本：`23699` / `23677`。
- F/alpha/structure 份额：`53.877574%` / `28.662760%` / `17.459667%`。
- 多工况 material fraction：`45.454545%` / `0.000000%` / `72.727273%`。
- P0→P2b/P1/P3b false-safe 绝对下降：`+1.995865 percentage points` / `+1.080214 percentage points` / `+2.249040 percentage points`。
- F/alpha/structure top-1 recovery：`47.058824%` / `30.514706%` / `89.338235%`（次级诊断）。
- stress false-safe event fraction：`2.841678%`。

## 解释纪律

决定主要依赖工程主域的替换 MSE、false-safe 和跨工况稳定性；候选 ranking 次之；Pearson/Spearman 不参与因果门禁。P2c/P3c 不进入主要门禁。若未来改变 gauge、候选 bank、工况主域或 Jd/Jq，上述决定必须重新注册和运行。

## 下一项目映射

A→F estimator bandwidth/predictive F/ESO；B→在线或调度 alpha_d/alpha_q；C→受计算量约束的扩展仿射；D→高阶/更精确离散；稳定 6x/12x→单独周期扰动审计；E→先修实现；F→停止超局部鲁棒改进。只有当前实际命中的 `C` 路线被推荐，其他条目保留为审计映射。
