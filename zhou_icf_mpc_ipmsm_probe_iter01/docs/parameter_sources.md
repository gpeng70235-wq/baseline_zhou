# Parameter sources

| parameter | value | source/status |
|---|---:|---|
| `Rs` | 0.0957 ohm | Zhou et al. (2025), carried through Iteration 11 |
| `psi_f` | 0.027 Wb | Zhou et al. (2025), carried through Iteration 11 |
| pole pairs | 12 | Zhou et al. (2025), carried through Iteration 11 |
| inertia | 0.01015 kg m^2 | Zhou et al. (2025), retained for documentation; fixed-speed plant does not integrate mechanics |
| `Ts` | 100 us | Zhou et al. (2025)/Iteration 11 |
| P0 `Ld=Lq` | 1.0 mH | declared analytical SMPMSM degeneracy value |
| P1 `Ld`,`Lq` | 0.8, 1.2 mH | engineering IPMSM saliency assumption; not reported by Zhou et al. |
| `Vdc` | 48 V | low-voltage engineering probe assumption; deliberately not Iteration 11's identified 84 V |
| reference ramp | 5 ms | engineering probe assumption chosen to avoid an infeasible startup step; deliberately not Iteration 11's 20 ms |
| speed/current | 100 rpm, 10 A | nominal probe operating point |
| negative `id` | 0, -2, -4, -6 A | migration sweep definition |

Motor electrical constants have one authoritative location, `config/ipmsm_parameters.m`; they are not duplicated in the base configuration.
