# K/K+1/K+2 Sequence Diagram

```mermaid
sequenceDiagram
    participant ADC as ADC / sampled state
    participant EST as Dual-timescale estimator
    participant Z as Native Zhou ICF-MPC
    participant S2 as Frozen S2 layer
    participant PWM as PWM / plant

    ADC->>EST: row k: i(k), i(k-1), executed log u_app(k-1)
    EST->>EST: alpha posterior if slow gates pass; F posterior every trusted sample
    PWM-->>Z: pending(k) = post-S2 selected(k-1)
    EST->>Z: alpha_post(k), F_pred(k), i(k)
    Z->>Z: i_hat(k+1|k) with pending(k), exactly Ts
    Z->>Z: unchanged rectangle, native case/mode, selected_core(k)
    Z->>S2: native command
    S2->>S2: unchanged feasibility processing
    S2-->>Z: selected_final(k)
    Z->>Z: i_hat(k+2|k) with selected_final(k), exactly Ts
    Z->>Z: unchanged Jd/Jq thresholds and labels
    Z->>EST: native current margin/mode gap -> latch g_decision_next(k)
    PWM->>ADC: execute pending(k) over k to k+1
    S2->>PWM: queue selected_final(k) for k+1 to k+2
```

文字等价式：

```text
row k input: i(k), i(k-1), u_app(k-1), pending(k)
posterior update: alpha^+(k), F^+(k)
i_hat(k+1|k) = i(k) + Ts [F_pred(k) + alpha^+(k) .* u_pending_eq(k)]
native Zhou geometry -> selected_core(k)
frozen S2 -> selected_final(k)
i_hat(k+2|k) = i_hat(k+1|k) + Ts [F_pred(k) + alpha^+(k) .* u_selected_final_eq(k)]
Jd/Jq = [ref(k)-i_hat(k+2|k)]^2
selected_final(k) becomes pending/applied(k+1)
```
