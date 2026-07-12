# Assumptions and limitations

- Ideal two-level inverter and constant DC bus; no dead time or device drops.
- Constant mechanical speed; inertia is documented but mechanics are not integrated.
- Causal Euler ultralocal `F` estimate with a zero initial estimate.
- One-period digital delay: the pending command is applied now and the selected command is queued for the next period.
- Candidate voltage uses every sequence segment's execution midpoint; geometry uses the Iteration 11 `theta+1.5 omega Ts` angle.
- Case 2 retains Iteration 11 Table-I SAVV selection and phase flip. When printed Table-II algebra is ambiguous, the unambiguous geometric segment midpoint is used and documented.
- Infeasible voltage requests are projected only to keep the numerical plant safe; they remain marked infeasible/illegal and fail admission.
- No saturation, iron loss, thermal drift, parameter identification, measurement noise, or laboratory validation.

Consequently, passing results demonstrate code-path feasibility and internally consistent constraints, not a claim of hardware performance or exact reproduction of Iteration 11 paper metrics.
