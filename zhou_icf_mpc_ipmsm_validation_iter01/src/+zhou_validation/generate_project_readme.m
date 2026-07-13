function generate_project_readme(project,decision)
%GENERATE_PROJECT_README Update the user-facing project entry point.

fid=fopen(fullfile(project.root,'README.md'),'w','n','UTF-8');assert(fid>=0);
cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'# Zhou ICF-MPC IPMSM validation iter01\n\n');
fprintf(fid,'## Purpose\n\nA fully independent, reproducible validation baseline for Zhou ICF-MPC on an IPMSM.\n\n');
fprintf(fid,'## Research boundary\n\nThis project validates inheritance, saliency, negative id, plant-only mismatch, estimator controls and numerical closure. It does not add MTPA or propose a new controller.\n\n');
fprintf(fid,'## Current conclusion\n\n**%s. %s** — %s\n\n',decision.code,decision.title,decision.reason);
fprintf(fid,'## Structure\n\n`config/`, `src/`, `estimators/`, `experiments/`, `tests/`, `reference/`, `docs/`, `results/`, `plots/`, `diagnostics/`, `logs/`, `delivery/`.\n\n');
fprintf(fid,'## MATLAB\n\nValidated with MATLAB R2024b (`%s`).\n\n',project.matlab_version);
fprintf(fid,'## One-command run\n\n```matlab\ncd(''%s'')\nrun_all_ipmsm_validation\n```\n\n',project.root);
fprintf(fid,'## Quick test\n\n```matlab\np=initialize_project("quick_test"); [pass,results]=run_unit_tests(p);\n```\n\n');
fprintf(fid,'## Experiment matrix\n\nA0 strict P0; A1 six-condition P0/P1; A2 alpha modes; A3 negative id; A4 sensitivity; A5 stress; A6 estimators; A7 residual cause; A8 numerical closure.\n\n');
fprintf(fid,'## Results\n\nFormal run `%s`; open `results/summary/` and `plots/summary/%s/`.\n\n',project.run_id,project.run_id);
fprintf(fid,'## Handoff\n\nStart with `IPMSM_VALIDATION_HANDOFF.md`.\n\n');
fprintf(fid,'## GitHub branch\n\n`ipmsm-validation-iter01` (or its timestamped collision-safe successor).\n\n');
fprintf(fid,'## Known limits\n\nFixed-speed idealized simulation; see `docs/parameter_scope_and_limits.md`.\n\n');
fprintf(fid,'## Claims not supported\n\nNo hardware validation, temperature/saturation robustness, online Oracle, ESO novelty, or MTPA result is claimed.\n\n');
fprintf(fid,'## Continued-development rules\n\nDo not modify the frozen Case/duration/frame/vector/constraint/F-baseline contracts in this iter01. Fork a new iteration for controller changes.\n');
end
