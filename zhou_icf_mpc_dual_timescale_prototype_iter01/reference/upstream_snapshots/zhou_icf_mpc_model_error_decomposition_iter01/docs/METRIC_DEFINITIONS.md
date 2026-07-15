# Metric Definitions

## 预测残差与独立约束

对预测器 p：`e_p,d = id_actual(k+2)-id_pred_p(k+2|k)`，`e_p,q` 同理；`Jd_p=[id_ref(k)-id_pred_p]^2`，`Jq_p` 同理。actual J 使用同一 ref(k) 与 actual(k+2)。预测 joint pass 当且仅当 Jd、Jq 均 ≤ `0.16 A^2`。

- false-safe：预测 joint pass，actual joint fail。
- false-alarm：预测 joint fail，actual joint pass。
- RMS：`sqrt(mean(ed^2+eq^2))`；MSE 表中为 `mean(ed^2+eq^2)`。
- 最大连续 false-safe：逐 case 计算连续 true run，再取最大。
- S2-near：S2 触发行前后各 2 个样本。

## 注册贡献量（有符号 MSE 差）

```text
Delta_F_causal   = MSE(P0) - MSE(P2a)
Delta_F_instant  = MSE(P0) - MSE(P2b)
Delta_alpha      = MSE(P0) - MSE(P1)
Delta_joint      = MSE(P0) - MSE(P3b)
interaction      = MSE(P1)+MSE(P2b)-MSE(P0)-MSE(P3b)
F_Shapley        = 0.5*[(MSE(P0)-MSE(P2b))+(MSE(P1)-MSE(P3b))]
alpha_Shapley    = 0.5*[(MSE(P0)-MSE(P1))+(MSE(P2b)-MSE(P3b))]
two-period freeze= MSE(P3b)-MSE(P4)
Euler/segments   = MSE(P4)-MSE(P5)
structure total  = MSE(P3b)-MSE(P5)
remaining gap    = MSE(P5)
```

差值允许为负，负值表示该替换在注册数据上恶化，不能截断后再宣称收益。由于 F/alpha gauge，Shapley 是本 canonical physical split 下的对称归因，不是参数的普适可辨识证明。

## 候选指标

top-1/top-3/mode flip 均相对 P0；agreement/recovery 相对 P5。recovery 分母只包括 P0 与 P5 原本不同的 eligible 样本，new error 则记录 P0 原本与 P5 相同却被替换破坏的样本。P2c/P3c 因未来条件不进入有效 ranking。

## 相关性与频谱

Pearson/Spearman 和线性斜率只作描述；±10 样本互相关仅对 F/alpha 误差变量执行，其余变量显示 N/A（not evaluated）。因果判断必须来自 P0--P5 替换。频谱幅值为去均值残差的一侧 RMS，使用整数电气周期；1x 太小、参考变化、非定速或周期不足均标无效。

## 汇总口径

`REPRODUCTION_ALL` 包含全部 `24153` 样本；`ENGINEERING_PRIMARY` 排除 `range_class=stress_test`，用于 A--F 门禁；P2a/P3a 归因另使用所有预测器有限的公共交集 `24129`。三者不可混报。
