function generate_handoff_document(project,data,decision)
%GENERATE_HANDOFF_DOCUMENT Write a self-contained engineering handoff.

[branch,commit,remote]=git_metadata(project.root);
fid=fopen(fullfile(project.root,'IPMSM_VALIDATION_HANDOFF.md'),'w','n','UTF-8');
assert(fid>=0);cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'# IPMSM validation handoff\n\n');
fprintf(fid,'## 1. Purpose\n\nIndependent evidence chain for Zhou ICF-MPC compatibility with an IPMSM; no MTPA or new controller is introduced here.\n\n');
fprintf(fid,'## 2. Project path\n\n`%s`\n\n',project.root);
fprintf(fid,'## 3. Source baselines and SHA-256\n\nSee `SOURCE_MANIFEST.sha256`, `reference/manifests/`, and `docs/baseline_inheritance_mapping.md`. Iteration 11 is a fixed source snapshot, not an authority freeze.\n\n');
fprintf(fid,'## 4. Git state\n\n- branch: `%s`\n- commit at report generation: `%s`\n- remote: `%s`\n\n',branch,commit,remote);
fprintf(fid,'## 5. Directory structure\n\nCode is under `src/`, configuration under `config/`, experiments under `experiments/`, tests under `tests/`, immutable evidence under `reference/`, run artifacts under `results/<experiment>/<run_id>/` and `plots/<experiment>/<run_id>/`.\n\n');
fprintf(fid,'## 6. One-command run\n\n```powershell\n& ''D:\\software\\MATLAB R2024b\\bin\\matlab.exe'' -batch "cd(''%s''); run_all_ipmsm_validation"\n```\n\n',project.root);
fprintf(fid,'## 7. Configuration entries\n\n`config/base_parameters.m`, `ipmsm_parameters.m`, `experiment_matrix.m`, `estimator_definitions.m`, `acceptance_thresholds.m`, `parameter_mismatch_definitions.m`, `implementation_assumptions.m`.\n\n');
fprintf(fid,'## 8. Experiment entries\n\n`experiments/experiment_A0_strict_P0_regression.m` through `experiment_A8_numerical_closure.m`. A0 is the mandatory stop gate.\n\n');
fprintf(fid,'## 9. Result entries\n\nAll summary CSVs are in `results/summary/`; formal run `%s` detailed artifacts are in each experiment directory.\n\n',project.run_id);
fprintf(fid,'## 10. Priority plots\n\n`final_decision_dashboard.png`, `p0_current_pointwise_difference.png`, `ipmsm_condition_rmse_heatmap.png`, `F_estimated_vs_interval_oracle.png`, `rk4_convergence.png` under the run-scoped plot directories.\n\n');
fprintf(fid,'## 11. Gate state\n\n- tests: **%s**\n- A0: **%s**\n- A1 legality: **%s**\n- numerical closure: **%s**\n\n', ...
    passfail(data.tests_pass),passfail(data.p0_pass),passfail(data.A1_gate),passfail(decision.numerical_gate_pass));
fprintf(fid,'## 12. Formal conclusion\n\n**%s. %s** — %s\n\n',decision.code,decision.title,decision.reason);
fprintf(fid,'## 13. Unresolved questions\n\nHardware behavior, magnetic saturation, temperature, sensor/noise realism, mechanical speed-loop interaction, and causal estimator redesign remain outside this validation.\n\n');
fprintf(fid,'## 14. Excluded explanations\n\nThe project separately checks frame inheritance, Case/duration legality, queue alignment, integer-cycle THD, plant-only mismatch, offline Oracle, and RK4 refinement. See diagnostics before attributing causality.\n\n');
fprintf(fid,'## 15. Claims that are not allowed\n\nDo not call ESO an innovation; do not call the Oracle online; do not translate sensitivity into temperature/saturation; do not call stress cases a real envelope; do not call Iteration 11 an authority freeze.\n\n');
fprintf(fid,'## 16. Single next recommendation\n\n%s\n\n',next_step(decision));
fprintf(fid,'## 17. Constraints that must remain frozen\n\nOne-beat selected/queued/applied order; execution-segment midpoint frame definitions; Case 1/2/3 and Table-I policy; six-sector vector table; duration formulas; applied-voltage F history; independent d/q rectangle; original algebraic F parameters.\n\n');
fprintf(fid,'## 18. Reproduce this formal run\n\nRun the command in section 6. A new run_id is intentionally generated; compare its summaries with run `%s`. The old run is never overwritten.\n\n',project.run_id);
fprintf(fid,'## 19. GitHub remote\n\n`https://github.com/gpeng70235-wq/baseline_zhou.git`\n\n');
fprintf(fid,'## 20. Reading order\n\n1. `VALIDATION_DECISION.md`\n2. `FINAL_IPMSM_VALIDATION_REPORT.md`\n3. `diagnostics/p0_regression_diagnosis.md`\n4. `diagnostics/residual_rootcause_evidence.md`\n5. `docs/baseline_inheritance_mapping.md`\n');
end

function [branch,commit,remote]=git_metadata(root)
[~,branch]=system(sprintf('git -C "%s" branch --show-current',fileparts(root)));branch=strtrim(branch);
[~,commit]=system(sprintf('git -C "%s" rev-parse HEAD',fileparts(root)));commit=strtrim(commit);
[~,remote]=system(sprintf('git -C "%s" remote get-url origin',fileparts(root)));remote=strtrim(remote);
end
function value=passfail(x),if x,value='PASS';else,value='FAIL';end,end
function value=next_step(d)
switch d.code
    case "A",value='Create a separate MTPA iteration without changing this baseline.';
    case "B",value='Improve and revalidate the causal F estimator before MTPA.';
    case "C",value='Improve and revalidate the input gain before MTPA.';
    case "D",value='Keep this as the baseline; do not manufacture a new research claim.';
    otherwise,value='Resolve the failed or ambiguous gate before MTPA.';
end
end
