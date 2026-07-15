function tests = test_path_isolation
tests = functiontests(localfunctions);
end

function test_design_functions_resolve_only_inside_project(testCase)
root=fileparts(fileparts(mfilename('fullpath')));
resolved=which('design.reference_predictor');
verifyTrue(testCase,startsWith(resolved,root,'IgnoreCase',true));
verifyFalse(testCase,contains(path,'zhou_icf_mpc_model_error_decomposition_iter01'));
verifyTrue(testCase,isfile(fullfile(root,'audit','SOURCE_SHA256_BEFORE.csv')));
end
