# Run and Reproduce

```matlab
cd('C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_dual_timescale_prototype_iter01')
run_dual_timescale_prototype('all')
```

Individual modes are inventory, wiring, baseline, smoke, calibration, minimal, full, ablation, sensitivity, timing and audit. `full`, `ablation`, `sensitivity` and `timing` refuse to run while the minimal gate is failed.
To force computation rather than cache reuse, remove only this project's `results/cache` directory after verifying its absolute path. Never remove an upstream directory.
MATLAB startup restores the default path and adds only root, config and src inside this prototype.
