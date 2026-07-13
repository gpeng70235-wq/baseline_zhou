# Project structure

The root contains only the two MATLAB entry points, README, final decision/report, handoff, GitHub report, and source manifest. Configuration, code, estimators, experiments, tests, frozen references, documents, run-scoped results/plots, diagnostics, logs, and delivery inventories are separated into their named directories.

`src/+zhou_iter11_ref` and `src/+zhou_ipmsm` are independent executable packages. `reference/iter11/source_snapshot` is byte-for-byte evidence and is never on the MATLAB path.
