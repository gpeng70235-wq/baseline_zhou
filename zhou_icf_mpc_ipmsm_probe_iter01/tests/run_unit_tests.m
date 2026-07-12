function pass = run_unit_tests(cfg) %#ok<INUSD>
%RUN_UNIT_TESTS Run the required named suite and preserve actionable diagnostics.
root = fileparts(fileparts(mfilename('fullpath')));
unit_root = fullfile(root,'tests','unit');
expected_files = { ...
    'test_project_isolation.m','test_ipmsm_reduces_to_smpmsm.m', ...
    'test_ipmsm_dq_equation_signs.m','test_ipmsm_torque_equation.m', ...
    'test_alpha_d_alpha_q_usage.m','test_frame_angle_patch_preserved.m', ...
    'test_nonzero_id_reference_path.m','test_no_negative_duration_ipmsm.m', ...
    'test_no_illegal_command_ipmsm.m'};
for index = 1:numel(expected_files)
    assert(isfile(fullfile(unit_root,expected_files{index})), ...
        'ZhouIPMSM:MissingUnitTest','Required test is missing: %s',expected_files{index});
end
suite = testsuite(unit_root,'IncludeSubfolders',true);
assert(~isempty(suite) && numel(suite)>=numel(expected_files), ...
    'ZhouIPMSM:EmptyUnitSuite','Unit-test discovery returned too few tests.');
results = run(suite);
pass = ~isempty(results) && all([results.Passed]);

log_path = fullfile(root,'logs','unit_test_log.txt');
fid = fopen(log_path,'w','n','UTF-8');
assert(fid>=0,'ZhouIPMSM:UnitLogOpen','Cannot write unit-test log.');
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'Unit tests: %d total, %d passed, %d failed, %d incomplete\n\n', ...
    numel(results),nnz([results.Passed]),nnz([results.Failed]),nnz([results.Incomplete]));
for index = 1:numel(results)
    fprintf(fid,'[%s] passed=%d failed=%d incomplete=%d duration=%.6g s\n', ...
        results(index).Name,results(index).Passed,results(index).Failed, ...
        results(index).Incomplete,results(index).Duration);
    if results(index).Failed || results(index).Incomplete
        fprintf(fid,'%s\n',diagnostic_report(results(index)));
    end
end
clear cleanup;
assert(pass,'ZhouIPMSM:UnitTests','Unit tests failed; see logs/unit_test_log.txt.');
end

function report = diagnostic_report(result)
try
    report = result.Details.DiagnosticRecord.Report;
catch
    report = evalc('disp(result.Details)');
end
end
