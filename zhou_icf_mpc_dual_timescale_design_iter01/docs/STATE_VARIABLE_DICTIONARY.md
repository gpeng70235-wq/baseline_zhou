# State Variable Dictionary

| 状态 | 尺寸/类型 | 单位 | 行 k 含义 | 初值 | 边界 |
|---|---|---|---|---|---|
| `alpha_hat_d/q` | 2x1 double | A/(V·s) | posterior input gain | 1250 / 833.333333 | per-axis 0.5x to 1.5x initial |
| `F_hat_d/q` | 2x1 double | A/s | fast posterior lumped term | 0 / 0 | ±5e5 |
| `F_previous_d/q` | 2x1 double | A/s | previous posterior for trend | 0 / 0 | ±5e5 |
| `u_bar_d/q` | 2x1 double | V | applied-voltage low-pass state | first trusted u or 0 | finite |
| `y_bar_d/q` | 2x1 double | A/s | derivative low-pass state | first trusted y or 0 | finite |
| `u_energy_window_d/q` | 2x1 double | V² | rolling high-pass energy | 0 | nonnegative |
| `regressor_window_d/q` | 2xN double | normalized | `[1,u_hp/u_scale]` history | empty | N=20 |
| `decision_gate_latched` | scalar logical | none | gate from previous native decision | false | false/true |
| `alpha_freeze_count_d/q` | 2x1 uint32 | cycles | consecutive alpha freezes | 0 | saturating counter |
| `good_window_count_d/q` | 2x1 uint8 | windows | consecutive reactivation windows | 0 | 0..3 |
| `zero_vector_run` | uint16 | cycles | consecutive zero-vector executions | 0 | saturating counter |
| `history_valid` | logical | none | i(k-1), u_app(k-1) available | false | false/true |
| `sample_index` | uint64 | cycles | control row count | 0 | monotonic |

d/q 数组必须按列独立更新，任何整向量覆盖都要有显式 mask。目标电压不是状态，真实 Ld/Lq 不是状态，未来实际电流不是状态。
