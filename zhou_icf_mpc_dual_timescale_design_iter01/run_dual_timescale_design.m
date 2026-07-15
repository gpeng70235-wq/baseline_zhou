function report = run_dual_timescale_design(mode)
%RUN_DUAL_TIMESCALE_DESIGN Reproduce the isolated design audit.
% This entry point never adds an upstream path and never calls a controller.

if nargin == 0
    mode = "all";
end
mode = lower(string(mode));
valid = ["inventory","literature","timing","design","audit","all"];
assert(isscalar(mode) && any(mode==valid),'DualTimescale:InvalidMode', ...
    'Mode must be inventory, literature, timing, design, audit, or all.');

root = fileparts(mfilename('fullpath'));
addpath(fullfile(root,'src'));
cleanup = onCleanup(@()rmpath(fullfile(root,'src'))); %#ok<NASGU>
report = struct('root',root,'mode',mode,'timestamp',datetime('now'), ...
    'controller_connected',false);

if mode=="inventory" || mode=="all"
    report.inventory = run_inventory_check(root);
end
if mode=="literature" || mode=="all"
    report.literature = run_literature_check(root);
end
if mode=="timing" || mode=="all"
    report.timing = run_timing_check(root);
end
if mode=="design" || mode=="all"
    report.design = run_reference_design(root);
end
if mode=="audit" || mode=="all"
    report.audit = run_test_audit(root);
end
end

function out = run_inventory_check(root)
before_path = fullfile(root,'audit','SOURCE_SHA256_BEFORE.csv');
after_path = fullfile(root,'audit','SOURCE_SHA256_AFTER.csv');
projects_path = fullfile(root,'audit','SOURCE_PROJECTS.csv');
assert(isfile(before_path) && isfile(projects_path), ...
    'DualTimescale:MissingInventory','Frozen inventory artifacts are missing.');
before = readtable(before_path,'TextType','string','VariableNamingRule','preserve');
project_lines = readlines(projects_path);
project_count = nnz(strlength(strtrim(project_lines))>0)-1;
out = struct('project_count',project_count, ...
    'before_file_count',height(before), ...
    'after_file_count',NaN,'changed_file_count',NaN,'pass',false);
if isfile(after_path)
    after = readtable(after_path,'TextType','string','VariableNamingRule','preserve');
    key_before = before.project_id+"|"+before.relative_path;
    key_after = after.project_id+"|"+after.relative_path;
    [common,ia,ib] = intersect(key_before,key_after,'stable');
    changed = nnz(before.sha256(ia)~=after.sha256(ib));
    added = height(after)-numel(common);
    removed = height(before)-numel(common);
    out.after_file_count = height(after);
    out.changed_file_count = changed+added+removed;
    out.pass = out.changed_file_count==0;
end
end

function out = run_literature_check(root)
index_path = fullfile(root,'references','SOURCE_PDF_INDEX.csv');
assert(isfile(index_path),'DualTimescale:MissingLiteratureIndex', ...
    'SOURCE_PDF_INDEX.csv is missing.');
T = readtable(index_path,'TextType','string','VariableNamingRule','preserve');
present = false(height(T),1);
for k=1:height(T)
    present(k) = isfile(T.absolute_path(k));
end
assert(all(present & T.found==1),'DualTimescale:MissingPaper', ...
    'One or more indexed source PDFs are unavailable.');
out = struct('indexed_count',height(T),'found_count',nnz(present), ...
    'missing_count',nnz(~present),'pass',height(T)==8 && all(present));
end

function out = run_timing_check(root)
required = ["icf_mpc_step.m";"sequence_equivalent_dq_voltage.m"; ...
    "apply_feasibility_layer.m";"TIMING_ALIGNMENT_AUDIT.md"; ...
    "ORIGINAL_PREDICTOR_DEFINITION.md"];
prov_path = fullfile(root,'audit','COPIED_FILE_PROVENANCE.csv');
assert(isfile(prov_path),'DualTimescale:MissingProvenance', ...
    'COPIED_FILE_PROVENANCE.csv is missing.');
P = readtable(prov_path,'TextType','string','VariableNamingRule','preserve');
names = string(cellfun(@(x)char(java.io.File(x).getName()), ...
    cellstr(P.destination_absolute_path),'UniformOutput',false));
found = arrayfun(@(x)any(names==x),required);
assert(all(found),'DualTimescale:TimingEvidenceMissing', ...
    'A required timing evidence copy is absent.');
out = struct('required_files',numel(required),'found_files',nnz(found), ...
    'mapping',"i(k)->pending(k)->i_hat(k+1|k)->post-S2 selected(k)->i_hat(k+2|k)", ...
    'pass',all(found));
end

function out = run_reference_design(root)
cfg = design.project_parameter();
gate = struct('g_alpha_dq',[true;true],'alpha_step_scale',1, ...
    'g_F_dq',[true;true],'g_decision_latched',true);
alpha0 = cfg.alpha_initial_A_per_Vs;
[alpha1,~] = design.reference_alpha_update(alpha0,[4;-3], ...
    alpha0.*[4;-3]+[120;-80],gate,cfg);
[F1,~,~] = design.reference_F_update([0;0],[-10;10], ...
    [2e4;-1e4],[5;-4],alpha1,gate,cfg);
pred = design.reference_predictor([0;10],[2;3],[4;5],F1,[0;0], ...
    alpha1,true,cfg);
iterations = 20000;
timer = tic;
for k=1:iterations
    design.reference_alpha_update(alpha0,[4;-3], ...
        alpha0.*[4;-3]+[120;-80],gate,cfg);
    design.reference_F_update([0;0],[-10;10],[2e4;-1e4], ...
        [5;-4],alpha1,gate,cfg);
end
elapsed = toc(timer)/iterations;
timing = table(datetime('now'),iterations,elapsed,elapsed*1e6, ...
    'VariableNames',{'measured_at','iterations','seconds_per_two_axis_update', ...
    'microseconds_per_two_axis_update'});
writetable(timing,fullfile(root,'results','summary','matlab_reference_timing.csv'));
out = struct('alpha_post',alpha1,'F_post',F1, ...
    'i_hat_k2',pred.i_hat_k2_given_k_A, ...
    'seconds_per_two_axis_reference_update',elapsed, ...
    'controller_connected',false,'pass',all(isfinite(pred.i_hat_k2_given_k_A)));
end

function out = run_test_audit(root)
suite = testsuite(fullfile(root,'tests'),'IncludeSubfolders',true);
results = run(suite);
out = struct('passed',nnz([results.Passed]),'failed',nnz([results.Failed]), ...
    'incomplete',nnz([results.Incomplete]),'total',numel(results), ...
    'pass',all([results.Passed]));
assert(out.pass,'DualTimescale:UnitTestFailure', ...
    '%d of %d unit tests failed.',out.failed,out.total);
end
