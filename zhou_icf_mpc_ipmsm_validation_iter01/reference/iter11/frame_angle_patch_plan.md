# Frame-angle patch plan

| Path | Legacy angle/interval | Iter11 definition | Changed? |
|---|---|---|---|
| pending k+1 prediction | stored selection angle θ(k−1), applied current cycle | U3 at θ(k)+ω segment midpoint | yes |
| selected geometry | θ(k), command applied next cycle | execution-center θ(k)+1.5ωTs | yes |
| selected k+2 prediction | θ(k) | per-segment U3 at θ(k)+ω(Ts+segment midpoint) | yes |
| Case/duration generation | original analytic geometry | unchanged algorithms, rotated geometry angle | angle only |
| F history | actual midpoint applied dq | unchanged | no |
| plant RK4 | evolving physical θ(t) | unchanged | no |
| selected/queued/applied | one queue delay | unchanged | no |

Only `icf_mpc_step.m`, `run_closed_loop.m`, configuration, and the new sequence-equivalent voltage helper participate in the control change.
