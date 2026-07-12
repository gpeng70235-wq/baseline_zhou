# Migration code audit

- The final source mapping is in `docs/iter11_inheritance_mapping.md`; no MATLAB file is mislabeled byte-identical.
- Runtime namespaces contain no Iteration 10/11/Wu/audit path and no target source references an old result file or run ID.
- The copied paper PDF is byte-identical to Iteration 11 (`CDCE796661012E0B682B8D9A98F6F36FA7EEF6A5093BE1415EECE5B56187B04C`).
- The 55 entries in `reference/iter11_source_manifest.sha256` match the current Iteration 11 config/src/tests snapshot. The subset-manifest hash is `BBEF10D8FE9EF759E995DD49A7002E4F0FC43A288C8D16A7DE96032FDCEC2A14`.
- Iteration 11's own source manifest has 73/73 matching entries; its manifest hash is `64AAA8BA0E269382D1371128C799B14F0C68A391597C6EF586B593DCD930D369`.
- Git cannot provide a pre-task diff proof because this workspace has no `HEAD` and Iteration 11 is untracked. The matching independent hash inventories are strong current-state evidence, not an immutable historical proof.
- Generated Iteration 11 results, plots, diagnostics, logs, caches, and run IDs were excluded.
