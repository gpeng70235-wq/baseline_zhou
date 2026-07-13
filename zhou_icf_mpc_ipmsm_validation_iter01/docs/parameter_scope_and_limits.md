# Parameter scope and limits

Nominal IPMSM data are `Ld=0.8 mH`, `Lq=1.2 mH`, `Rs=0.0957 ohm`, `psi_f=0.027 Wb`, and 12 pole pairs. A4 scans one plant parameter at 0.8–1.2 while the controller remains nominal. This is parameter sensitivity, not temperature or magnetic saturation.

A5 uses 0.5/1.5 inductance/resistance extremes, 0.8/1.2 flux extremes, and one combined mismatch. These are labeled stress tests and are not a real operating range or a real-world robustness claim. Speed is externally fixed; mechanical dynamics, iron loss, sensor quantization, switching-device nonidealities, and thermal effects are outside scope.
