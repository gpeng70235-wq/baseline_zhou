# Model equation mapping

The IPMSM plant is

```text
did/dt = (ud - Rs id + omega_e Lq iq) / Ld
diq/dt = (uq - Rs iq - omega_e (Ld id + psi_f)) / Lq
```

and electromagnetic torque is

```text
Te = 1.5 p [psi_f iq + (Ld - Lq) id iq].
```

`calculate_torque_components` reports magnet and reluctance terms separately. With `Ld=Lq=Ls`, reluctance torque becomes exactly zero and the derivatives reduce to the Iteration 11 SMPMSM equations. P0 checks those identities against an independent closed-form oracle over multiple states and voltages.

The controller uses `alpha=[1/Ld;1/Lq]` in axis-specific mode. The comparison mode deliberately uses one `1/mean([Ld,Lq])` gain to quantify the consequence of retaining an SMPMSM-like common inductance.

Each constant inverter switching segment is integrated with RK4. Park voltage is recomputed at the RK4 start, midpoint, and endpoint sub-times, so electrical-frame rotation is not frozen at one segment midpoint in the plant.
