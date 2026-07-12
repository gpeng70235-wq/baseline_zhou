# Migration plan

1. Record the Iteration 11 source inventory and inheritance decisions before implementation.
2. Treat Iteration 11 as read-only; copy no generated artifact or run ID.
3. Adapt motor-independent controller, Case geometry, dwell sequence, inverter, estimator, frame, simulation, and metric logic into the local namespace.
4. Replace the SMPMSM plant and torque equations with explicit IPMSM functions; use independent `alpha_d=1/Ld` and `alpha_q=1/Lq`.
5. Establish the analytical `Ld=Lq` degeneracy gate, then admit saliency, alpha comparison, and negative-`id` in order.
6. Generate run-isolated outputs, the final report, and finally a binary-safe source manifest.
7. Verify path isolation, formal artifacts, manifest hashes, and the read-only Iteration 11 source snapshot.

An exact replay of old Iteration 11 numerical result files is intentionally outside this migration because those generated files were prohibited from copying. P0 therefore tests the analytical degeneracy and inherited safety/constraint contract under the new project's declared configuration.
