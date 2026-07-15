function tests = test_no_future_data
tests = functiontests(localfunctions);
end

function test_public_signatures_exclude_future_actual_current(testCase)
verifyEqual(testCase,nargin('design.reference_alpha_update'),5);
verifyEqual(testCase,nargin('design.reference_F_update'),7);
verifyEqual(testCase,nargin('design.reference_predictor'),8);
root=fileparts(fileparts(mfilename('fullpath')));
code=fileread(fullfile(root,'src','+design','reference_predictor.m'));
verifyFalse(testCase,contains(code,'i_actual_k1'));
verifyFalse(testCase,contains(code,'Ld_H'));
verifyFalse(testCase,contains(code,'Lq_H'));
end
