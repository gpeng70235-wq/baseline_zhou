# CHANGELOG

## 2026-07-15 15:21:57 +08:00 — v1.0.0

- 建立完全隔离的 `zhou_icf_mpc_model_error_decomposition_iter01`。
- 冻结并登记五个上游，生成 BEFORE/AFTER SHA256 和最小复制 provenance；文档生成时变化数为 `0`。
- 复现 `10/10` 项基线门禁。
- 对 `24` 个工况、`24153` 个样本完成 P0、P1、P2a/b/c、P3a/b/c、P4、P5 两拍预测。
- 加入 F/alpha gauge 审计字段、P0 公式复现、P5 对象复现、selected(k)=applied(k+1) 和候选 P5 步长收敛断言。
- 生成 8 个注册汇总 CSV、离线诊断候选比较、整数电气周期频谱、状态相关性与 15 类图片。
- 按预注册门禁给出结论 `C`：F and alpha jointly dominate。
- prototype 保持关闭；未修改闭环控制器，也未加入 ESO/RLS/高阶或经验收紧方法。
