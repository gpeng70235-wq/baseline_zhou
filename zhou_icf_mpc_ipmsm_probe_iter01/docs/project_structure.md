# Project structure

The root contains only the initializer, one-command runner, README, changelog, final report, and source manifest. Parameter functions live in `config/`; reusable functions live in the `zhou_ipmsm` package under `src/`; `experiments/` contains only the four gate entry functions; and `tests/` contains only automated checks.

Formal data, images, diagnostics, and logs are never mixed. Each formal experiment creates `results/<experiment>/<run_id>/`, `plots/<experiment>/<run_id>/`, and a configuration MAT file under the result run's `config_snapshot/`. Summary CSVs are append-preserving and evolve their schema without losing old rows.

The initializer adds only the project root, `config`, `src`, `experiments`, and `tests` to MATLAB. It does not use `genpath`, so generated result directories never enter function resolution.
