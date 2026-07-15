# Order Tracking Protocol

Time FFT is not the mechanism test. Each registered complete cycle is independently resampled from native samples to a uniform rotor-electrical-angle grid.

## Implementation

- Grid density: **256 points per electrical cycle**.
- Interpolation: linear; the small endpoint extrapolation fraction and native-grid round-trip RMS are retained per coefficient row.
- Real-axis fit: `c0+c6c cos(6 theta)+c6s sin(6 theta)+c12c cos(12 theta)+c12s sin(12 theta)`.
- Amplitude: `sqrt(c_cos^2+c_sin^2)`; phase: `atan2(-c_sin,c_cos)`.
- Complex residual: positive- and negative-rotating coefficients are both retained, so rotation direction is not selected after seeing the result.
- Fits are per complete cycle. Calibration and validation labels come only from the preregistered time split.

## Coverage

Valid windows: **14**; cycles: **49**; coefficient rows: **392**.
The maximum interpolation round-trip RMS is `0.0101136 A`; maximum endpoint extrapolated fraction is `0.0195312`.

Fixed-speed windows are evaluated by both this angle-domain method and the independent Hann-FFT/exact-regression table.
