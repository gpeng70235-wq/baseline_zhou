function status = run_all_ipmsm_validation()
%RUN_ALL_IPMSM_VALIDATION One-command gated A0-A8 formal validation.

project=initialize_project();
log_path=fullfile(project.root,'logs','matlab_execution_log.txt');
diary(log_path);diary_cleanup=onCleanup(@() diary('off')); %#ok<NASGU>
fprintf('\n===== formal run %s | %s =====\n',project.run_id,project.timestamp);
status=struct('run_id',project.run_id,'tests',false,'A0',false,'A1',false, ...
    'A2',false,'A3',false,'A4',false,'A5',false,'A6',false,'A7',false, ...
    'A8',false,'plots',false,'reports',false);
try
    [status.tests,test_results]=run_unit_tests(project);
    assert(status.tests,'ZhouValidation:CoreTests','Core unit tests failed.');
    fprintf('A0 strict dual-closed-loop regression...\n');
    [p0_summary,p0_pointwise,status.A0]=experiment_A0_strict_P0_regression(project);
    if ~status.A0
        write_failed_gate(project,'A0','Strict pointwise P0 regression failed.');
        error('ZhouValidation:P0Gate','A0 failed; A1-A8 were not executed.');
    end

    fprintf('A1 six-condition P0/P1 matrix...\n');
    [A1,status.A1]=experiment_A1_ipmsm_condition_matrix(project);
    fprintf('A2 alpha-mode matrix...\n');
    [A2,A2delta,alpha_assessment]=experiment_A2_alpha_mode_matrix(project);status.A2=true;
    fprintf('A3 negative-id matrix...\n');
    A3=experiment_A3_negative_id_matrix(project);status.A3=true;
    fprintf('A4 plant-only parameter sensitivity...\n');
    A4=experiment_A4_parameter_sensitivity(project);status.A4=true;
    fprintf('A5 labeled stress matrix...\n');
    A5=experiment_A5_parameter_stress(project);status.A5=true;
    fprintf('A6 estimator comparison...\n');
    A6=experiment_A6_F_estimator_comparison(project);status.A6=true;
    fprintf('A7 residual root-cause evidence...\n');
    [A7,worst_trace]=experiment_A7_residual_rootcause(project,A1,A2delta,A3,A6);status.A7=true;
    fprintf('A8 numerical closure...\n');
    A8=experiment_A8_numerical_closure(project);status.A8=true;

    data=struct('tests_pass',status.tests,'test_results',test_results, ...
        'p0_pass',status.A0,'p0_summary',p0_summary,'p0_pointwise',p0_pointwise, ...
        'A1_gate',status.A1,'A1',A1,'A2',A2,'A2delta',A2delta, ...
        'alpha_assessment',alpha_assessment,'A3',A3,'A4',A4,'A5',A5, ...
        'A6',A6,'A7',A7,'worst_trace',worst_trace,'A8',A8);
    save(fullfile(project.root,'results','summary',project.run_id, ...
        'validation_data.mat'),'data','-v7.3');
    decision=zhou_validation.generate_validation_decision(project,data);
    fprintf('Generating twenty formal plots...\n');
    plot_paths=zhou_validation.generate_all_plots(project); %#ok<NASGU>
    status.plots=true;
    zhou_validation.generate_final_report(project,data,decision);
    zhou_validation.generate_handoff_document(project,data,decision);
    zhou_validation.generate_project_readme(project,decision);
    zhou_validation.generate_inheritance_mapping(project);
    write_github_pending(project);
    status.reports=true;
    write_ledger(project,status,decision);
    zhou_validation.generate_manifests(project);
    fprintf('Formal run complete: %s | decision %s\n',project.run_id,decision.code);
catch exception
    log_runtime_error(project,exception);
    write_ledger(project,status,struct('code',"ERROR"));
    try,zhou_validation.generate_manifests(project);catch, end
    rethrow(exception);
end
end

function write_failed_gate(project,gate,message)
fid=fopen(fullfile(project.root,'diagnostics','failed_gates', ...
    sprintf('%s_%s.md',project.run_id,gate)),'w','n','UTF-8');
if fid<0,return;end;cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'# Failed gate: %s\n\n- run_id: `%s`\n- reason: %s\n',gate,project.run_id,message);
end
function log_runtime_error(project,e)
fid=fopen(fullfile(project.root,'diagnostics','runtime_errors', ...
    project.run_id+".txt"),'w','n','UTF-8');if fid<0,return;end
cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n%s\n\n%s',e.identifier,e.message,getReport(e,'extended'));
end
function write_ledger(project,status,decision)
fields={'tests','A0','A1','A2','A3','A4','A5','A6','A7','A8','plots','reports'};
values=false(1,numel(fields));for k=1:numel(fields),values(k)=status.(fields{k});end
row=cell2table([{string(project.run_id),string(project.timestamp),string(decision.code)} num2cell(values)], ...
    'VariableNames',[{'run_id','timestamp','decision'} fields]);
path_value=fullfile(project.root,'logs','run_ledger.csv');
if isfile(path_value),old=readtable(path_value,'TextType','string');row=[old;row];end
writetable(row,path_value);
end
function write_github_pending(project)
fid=fopen(fullfile(project.root,'GITHUB_DELIVERY_REPORT.md'),'w','n','UTF-8');assert(fid>=0);
cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,['# GitHub delivery report\n\n- remote: `https://github.com/gpeng70235-wq/baseline_zhou.git`\n' ...
    '- branch: `ipmsm-validation-iter01`\n- formal run: `%s`\n- push status: **PENDING POST-RUN DELIVERY**\n' ...
    '- project path: `%s`\n- handoff: `IPMSM_VALIDATION_HANDOFF.md`\n' ...
    '- final report: `FINAL_IPMSM_VALIDATION_REPORT.md`\n\n' ...
    'The post-run Git step must record the content commit and real push result; credentials are never stored here.\n'], ...
    project.run_id,project.root);
end
