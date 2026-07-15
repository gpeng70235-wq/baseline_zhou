function baseline(cfg)
%BASELINE Validate the frozen 24-case P0 data and export a canonical audit set.
fprintf('Phase 1: validating frozen B0 data...\n');
assert(isfile(cfg.frozen_model_error_csv), ...
    'Run inventory first; frozen model-error data is absent.');
opts = detectImportOptions(cfg.frozen_model_error_csv, 'TextType','string');
S = readtable(cfg.frozen_model_error_csv, opts);
vars = string(S.Properties.VariableNames);
missing = setdiff(cfg.required_source_fields, vars);
assert(isempty(missing), 'B0 source-data gate failed; missing fields: %s', ...
    strjoin(missing, ', '));

T = canonicalize(S);
caseIds = unique(T.case_id, 'stable');
caseCounts = groupcounts(T.case_id);
earlyCount = nnz(caseCounts < max(caseCounts));
primary = T.range_class ~= "stress_test";

checks = strings(0,1); pass = false(0,1); observed = strings(0,1); requirement = strings(0,1);
    function add(name, ok, obs, req)
        checks(end+1,1)=name; pass(end+1,1)=logical(ok); observed(end+1,1)=string(obs); requirement(end+1,1)=string(req);
    end

add("required_fields", isempty(missing), "missing="+strjoin(missing,";"), "all registered fields present");
add("registered_case_count", numel(caseIds)==cfg.expected_cases, numel(caseIds), cfg.expected_cases);
add("registered_sample_count", height(T)==cfg.expected_samples, height(T), cfg.expected_samples);
add("engineering_primary_false_safe", ...
    abs(mean(T.false_safe(primary))-cfg.expected_primary_false_safe)<=cfg.baseline_rate_tolerance, ...
    sprintf('%.12f',mean(T.false_safe(primary))), sprintf('%.12f',cfg.expected_primary_false_safe));
add("reproduction_all_false_safe", ...
    abs(mean(T.false_safe)-cfg.expected_all_false_safe)<=cfg.baseline_rate_tolerance, ...
    sprintf('%.12f',mean(T.false_safe)), sprintf('%.12f',cfg.expected_all_false_safe));
add("early_termination_semantics", earlyCount==cfg.expected_early_terminations, earlyCount, cfg.expected_early_terminations);

alignmentGap = max(abs([T.e_d-S.ed_P0; T.e_q-S.eq_P0]),[],'omitnan');
formulaGap = max(abs([T.Jd_pred-(T.id_ref-T.id_pred).^2; ...
    T.Jq_pred-(T.iq_ref-T.iq_pred).^2; ...
    T.Jd_actual-(T.id_ref-T.id_actual).^2; ...
    T.Jq_actual-(T.iq_ref-T.iq_actual).^2]),[],'omitnan');
add("k_to_k_plus_2_residual_alignment", alignmentGap<=cfg.numeric_tolerance, ...
    sprintf('max_gap_A=%.15g',alignmentGap), "<=2e-10 A and frozen timing audit");
add("J_formula_alignment", formulaGap<=cfg.numeric_tolerance, ...
    sprintf('max_gap_A2=%.15g',formulaGap), "<=2e-10 A^2");
add("P0_recompute_closure", max(S.P0_recompute_gap_A,[],'omitnan')<=cfg.numeric_tolerance, ...
    sprintf('max_gap_A=%.15g',max(S.P0_recompute_gap_A,[],'omitnan')), "<=2e-10 A");
add("plant_oracle_replay", max(S.P5_replay_gap_A,[],'omitnan')<=cfg.numeric_tolerance, ...
    sprintf('max_gap_A=%.15g',max(S.P5_replay_gap_A,[],'omitnan')), "<=2e-10 A");
add("decision_trace_fields", all(strlength(T.pending_command)>0 & strlength(T.applied_command)>0), ...
    sprintf('nonempty=%d/%d',nnz(strlength(T.pending_command)>0 & strlength(T.applied_command)>0),height(T)), ...
    "pending and applied traces retained for every row");
add("mode_and_S2_valid", all(isfinite(T.mode)) && all(ismember(T.S2_triggered,[0 1])), ...
    sprintf('modes=%s;S2_count=%d',strjoin(string(unique(T.mode)),';'),nnz(T.S2_triggered)), ...
    "finite mode and binary S2 flags");

[overlapN, overlapGap, flagMismatch] = prototype_overlap(cfg, T);
add("prototype_B0_overlap_rows", overlapN==4821, overlapN, 4821);
add("prototype_B0_numeric_overlap", overlapGap<=cfg.numeric_tolerance, ...
    sprintf('max_gap=%.15g',overlapGap), "<=2e-10");
add("prototype_B0_flag_overlap", flagMismatch==0, flagMismatch, 0);

B = table(checks, pass, observed, requirement, ...
    'VariableNames', {'check','pass','observed','requirement'});
zhou_periodic.write_table(B, fullfile(cfg.summary_dir,'baseline_data_check.csv'));
assert(all(B.pass), 'B0 source-data gate failed. See baseline_data_check.csv.');

zhou_periodic.write_table(T, cfg.canonical_csv);
write_doc(cfg, B, T, earlyCount, alignmentGap, formulaGap, overlapN, overlapGap);
fprintf('B0 gate PASS: %d cases, %d samples; no closed-loop rerun.\n', ...
    numel(caseIds), height(T));
end

function T = canonicalize(S)
T = table();
T.case_id = S.case_id;
T.category = S.case_category;
T.range_class = S.range_class;
T.sample_index = S.sample_index;
T.time_s = S.time_s;
T.speed_rpm = S.speed_rpm;
T.electrical_speed = S.electrical_speed;
T.electrical_angle = S.electrical_angle;
T.id = S.id;
T.iq = S.iq;
T.id_ref = S.id_ref;
T.iq_ref = S.iq_ref;
T.id_pred = S.id_pred_P0;
T.iq_pred = S.iq_pred_P0;
T.id_actual = S.id_actual;
T.iq_actual = S.iq_actual;
T.e_d = T.id_actual-T.id_pred;
T.e_q = T.iq_actual-T.iq_pred;
T.Jd_pred = S.Jd_P0;
T.Jq_pred = S.Jq_P0;
T.Jd_actual = S.Jd_actual;
T.Jq_actual = S.Jq_actual;
T.false_safe = logical(S.false_safe_P0);
T.false_alarm = logical(S.false_alarm_P0);
T.predicted_pass = ~(T.Jd_pred>0.16+1e-12 | T.Jq_pred>0.16+1e-12);
T.actual_joint_pass = logical(S.actual_joint_pass);
T.mode = S.mode;
T.S2_triggered = S.S2_triggered;
T.voltage_utilization = S.voltage_utilization;
T.u_app_d = S.selected_u_d;
T.u_app_q = S.selected_u_q;
T.pending_u_d = S.pending_u_d;
T.pending_u_q = S.pending_u_q;
T.selected_u_d = S.selected_u_d;
T.selected_u_q = S.selected_u_q;
T.pending_command = string(S.pending_u_d)+"|"+string(S.pending_u_q);
T.applied_command = S.applied_sequence_vector_ids+"|"+S.applied_sequence_durations_s;
if ismember('selected_sequence_vector_ids',S.Properties.VariableNames)
    T.selected_command = S.selected_sequence_vector_ids+"|"+S.selected_sequence_durations_s;
else
    T.selected_command = string(S.selected_u_d)+"|"+string(S.selected_u_q);
end
T.vector_mode = S.vector_mode;
T.phase = S.phase;
T.reference_rate_A_s = S.reference_rate_A_s;
T.distance_to_Jd_boundary = S.distance_to_Jd_boundary;
T.distance_to_Jq_boundary = S.distance_to_Jq_boundary;
T.boundary_margin_A2 = min(S.distance_to_Jd_boundary,S.distance_to_Jq_boundary);
T.residual_magnitude = hypot(T.e_d,T.e_q);
end

function [n, gap, mismatch] = prototype_overlap(cfg, T)
P = readtable(cfg.frozen_prototype_b0_csv, 'TextType','string');
common = intersect(unique(T.case_id), unique(P.case_id), 'stable');
n = 0; gap = 0; mismatch = 0;
for c = reshape(common,1,[])
    A = T(T.case_id==c,:); B = P(P.case_id==c,:);
    [tf,loc] = ismember(A.sample_index,B.sample_index);
    A = A(tf,:); B = B(loc(tf),:); n = n+height(A);
    D = [A.id_pred-B.i_pred_k2_d, A.iq_pred-B.i_pred_k2_q, ...
        A.Jd_pred-B.Jd_pred, A.Jq_pred-B.Jq_pred, ...
        A.Jd_actual-B.Jd_actual, A.Jq_actual-B.Jq_actual, ...
        A.pending_u_d-B.u_pending_d, A.pending_u_q-B.u_pending_q, ...
        A.selected_u_d-B.u_selected_final_d, A.selected_u_q-B.u_selected_final_q];
    gap = max(gap,max(abs(D),[],'all','omitnan'));
    mismatch = mismatch + nnz(A.false_safe~=logical(B.false_safe)) + ...
        nnz(A.false_alarm~=logical(B.false_alarm)) + nnz(A.mode~=B.mode) + ...
        nnz(A.S2_triggered~=B.S2_triggered);
end
end

function write_doc(cfg, B, T, earlyCount, alignGap, formulaGap, overlapN, overlapGap)
failed = B.check(~B.pass);
L = ["# Baseline Data Validation";""; ...
    "Result: **"+string(all(B.pass))+" ("+nnz(B.pass)+"/"+height(B)+" gates)**.";""; ...
    "## Data source";""; ...
    "The audit read the byte-identical frozen copy `reference/frozen_data/model_error_samples.csv`, whose source is the complete model-error snapshot inside the archived dual-timescale prototype. No B0 closed loop was rerun."; ...
    "The five-case prototype B0 export was used only as an independent pointwise overlap check.";""; ...
    "## Counts and rates";""; ...
    "- Registered cases: **"+numel(unique(T.case_id))+"**."; ...
    "- Aligned samples: **"+height(T)+"**."; ...
    "- ENGINEERING_PRIMARY (non-stress) false-safe: **"+sprintf('%.9f%%',100*mean(T.false_safe(T.range_class~="stress_test")))+"**."; ...
    "- REPRODUCTION_ALL false-safe: **"+sprintf('%.9f%%',100*mean(T.false_safe))+"**."; ...
    "- Early termination cases: **"+earlyCount+"**.";""; ...
    "## Timing and residual definition";""; ...
    "Every row is the original prediction made at `k` for the state at `k+2`. The current state columns `id/iq` are at `k`; `id_actual/iq_actual` are the aligned actual values at `k+2`."; ...
    "Residuals are `e_d(k)=id_actual(k+2)-id_pred(k+2|k)` and likewise for q. The maximum gap to the frozen `ed_P0/eq_P0` fields is `"+sprintf('%.15g',alignGap)+" A`."; ...
    "The maximum squared-cost formula gap is `"+sprintf('%.15g',formulaGap)+" A^2`. Jd/Jq limits remain fixed at `0.16 A^2`.";""; ...
    "## Independent reproduction overlap";""; ...
    "The separately generated prototype B0 export overlaps **"+overlapN+"** aligned rows; the maximum numeric gap is `"+sprintf('%.15g',overlapGap)+"`, with zero registered decision-flag mismatches.";""; ...
    "Failed gates: `"+strjoin(failed, "`, `")+"`. The workflow stops before spectral inference if any gate fails."];
writelines(L, fullfile(cfg.docs_dir,'BASELINE_DATA_VALIDATION.md'), 'Encoding','UTF-8');
end
