# Known Limitations

- Evidence stops at the five-case gate; no full-campaign claim is made.
- No ablation, local sensitivity, MATLAB timing microbenchmark, DSP WCET or HIL test was authorized after the failure.
- The frozen Zhou interface does not expose a runner-up mode cost; the prototype logs `abs(Jd-Jq)` as the native cost-gap adapter and records this in the compliance matrix.
- Simulation uses the frozen idealized plant and inherited limitations.
