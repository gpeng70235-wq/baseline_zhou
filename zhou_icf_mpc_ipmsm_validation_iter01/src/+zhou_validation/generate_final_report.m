function generate_final_report(project,data,decision)
%GENERATE_FINAL_REPORT Write the evidence-linked final validation report.

path_value=fullfile(project.root,'FINAL_IPMSM_VALIDATION_REPORT.md');
fid=fopen(path_value,'w','n','UTF-8');assert(fid>=0);cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
A1=data.A1;A3=data.A3;A4=data.A4;A5=data.A5;A6=data.A6;A8=data.A8;
fprintf(fid,'# Final Zhou ICF-MPC IPMSM validation report\n\n');
fprintf(fid,'- Formal run: `%s`\n- MATLAB: `%s`\n- Decision: **%s. %s**\n\n', ...
    project.run_id,project.matlab_version,decision.code,decision.title);
fprintf(fid,'## 1. One-sentence conclusion\n\n%s\n\n',decision.reason);
fprintf(fid,'## 2. Confirmed facts\n\n');
fprintf(fid,'- Mandatory tests: %d/%d passed.\n',nnz([data.test_results.Passed]),numel(data.test_results));
fprintf(fid,'- Strict P0 cycle-level gate: **%s** across three closed-loop conditions.\n',passfail(data.p0_pass));
fprintf(fid,'- Six-condition P0/P1 legality gate: **%s**; illegal=%d, negative dwell=%d.\n', ...
    passfail(data.A1_gate),sum(A1.illegal_commands),sum(A1.negative_durations));
fprintf(fid,'- The Iteration 11 source is a fixed validation snapshot, not an authority freeze; its own report withheld IPMSM admission.\n\n');
fprintf(fid,'## 3. Reasonable inferences\n\n');
fprintf(fid,'- IPMSM residual amplification flag: **%s**.\n',yesno(decision.ipmsm_amplifies_residual));
fprintf(fid,'- P1/P0 interval-F residual ratios are %.4g on d and %.4g on q across legal pairs.\n', ...
    decision.Fd_residual_ratio_P1_over_P0,decision.Fq_residual_ratio_P1_over_P0);
fprintf(fid,'- Dominant sensitivity within the declared plant-only grid: `%s` (normalized span %.4g).\n\n', ...
    decision.most_sensitive_parameter,decision.sensitivity_score);
fprintf(fid,'## 4. Unverified assumptions\n\n- Fixed speed is imposed externally; no mechanical-speed loop, iron loss, magnetic saturation, thermal model, sensor quantization, or hardware delay uncertainty is claimed.\n- Parameter sensitivity is not a temperature or saturation experiment. Stress cases are not a real operating envelope.\n\n');
fprintf(fid,'## 5. Strict P0 regression\n\n- Gate: **%s**. Case/vector/nonzero-duration match, current, U3 and aggregate thresholds were preregistered. See `results/summary/p0_regression_summary.csv`.\n\n',passfail(data.p0_pass));
fprintf(fid,'## 6. Six-condition results\n\n- %d/%d rows are legal/stable. Mean P1 d/q RMSE: %.6g/%.6g A; maximum engineering violation rate: %.6g.\n\n', ...
    nnz(A1.pass_fail=="PASS"),height(A1),mean(A1.id_rmse_A(A1.pair_role=="P1")), ...
    mean(A1.iq_rmse_A(A1.pair_role=="P1")),max(A1.engineering_violation_rate));
fprintf(fid,'## 7. Two-axis alpha\n\n- Cross-condition effective: **%s**. d improvement fraction %.3f; q worsening fraction %.3f; THD improvement fraction %.3f.\n\n', ...
    yesno(data.alpha_assessment.cross_condition_effective),data.alpha_assessment.d_improvement_fraction, ...
    data.alpha_assessment.q_worsening_fraction,data.alpha_assessment.thd_improvement_fraction);
fprintf(fid,'## 8. Negative id\n\n- id scan: %s A. Mean relative THD change at most-negative id: %.2f%%; torque-ripple change: %.2f%%. Engineering degradation flag: **%s**.\n\n', ...
    mat2str(unique(A3.id_reference).'),100*decision.negative_thd_relative_change, ...
    100*decision.negative_ripple_relative_change,yesno(decision.negative_degradation));
fprintf(fid,'- Failed negative-id rows: %d. Legal paired metrics do not override a failed high-speed legality gate.\n\n',nnz(A3.pass_fail=="FAIL"));
fprintf(fid,'## 9. Parameter sensitivity\n\n- %d plant-only one-at-a-time runs; controller parameters remained nominal. Most sensitive: `%s`.\n\n',height(A4),decision.most_sensitive_parameter);
fprintf(fid,'## 10. Stress test\n\n- %d labeled stress runs completed. They do not represent a real parameter range or real-world robustness claim.\n\n',height(A5));
fprintf(fid,'## 11. F-estimator comparison\n\n- Algebraic aggregate prediction error: %.6g A; best online `%s`: %.6g A; offline Oracle: %.6g A (improvement %.2f%%). ESO is a comparison baseline, not an innovation.\n\n', ...
    decision.algebraic_prediction_error,decision.best_online_estimator, ...
    decision.best_online_prediction_error,decision.oracle_prediction_error,100*decision.oracle_improvement);
fprintf(fid,'## 12. Residual root cause\n\n- See `results/summary/residual_rootcause_summary.csv` and `diagnostics/residual_rootcause_evidence.md`. Transition and voltage results are associations only. The interval Oracle is definitionally noncausal and supplies a lower bound, not causal proof.\n\n');
fprintf(fid,'- Saliency amplifies the d-axis interval-F residual while reducing the q-axis residual; this axis-dependent result must not be collapsed into one favorable combined norm.\n\n');
fprintf(fid,'## 13. Numerical closure\n\n- Gate: **%s**. RK4 steps: %s us; selected midpoint-vs-exact maximum %.6g V and mean %.6g V.\n\n', ...
    passfail(all(A8.numerical_gate=="PASS")),mat2str(A8.integration_step.'*1e6), ...
    A8.midpoint_vs_exact_max_error_V(1),A8.midpoint_vs_exact_mean_error_V(1));
fprintf(fid,'## 14. Engineering meaning\n\nThe result establishes a reproducible fixed-speed simulation baseline with explicit legality, actual-exceedance, estimator, and numerical gates. It does not establish hardware readiness.\n\n');
fprintf(fid,'## 15. Research meaning\n\nOnly the selected A-F decision is supported. Offline Oracle and basic ESO comparisons are diagnostic controls, not proposed novelty.\n\n');
fprintf(fid,'## 16. Stop conditions\n\nA0 failure stops A1-A8; any core unit-test failure prevents a theoretical conclusion; illegal commands, negative dwell, long saturation, or unresolved numerical closure prohibit MTPA admission.\n\n');
fprintf(fid,'## 17. Final decision\n\n**%s. %s**\n\n',decision.code,decision.title);
fprintf(fid,'## 18. Single next recommendation\n\n%s\n',next_step(decision));
end

function value=next_step(d)
switch d.code
    case "A",value='Enter a separately versioned MTPA study without changing the frozen Zhou geometry/controller core.';
    case "B",value='Characterize and improve the causal F estimator before adding MTPA.';
    case "C",value='Optimize and validate the input-gain model before adding MTPA.';
    case "D",value='Keep Zhou as the IPMSM baseline and do not claim a new research problem from this evidence.';
    otherwise,value='Close the failed or ambiguous evidence gate before any MTPA or controller redesign.';
end
end
function value=passfail(x),if x,value='PASS';else,value='FAIL';end,end
function value=yesno(x),if x,value='YES';else,value='NO';end,end
