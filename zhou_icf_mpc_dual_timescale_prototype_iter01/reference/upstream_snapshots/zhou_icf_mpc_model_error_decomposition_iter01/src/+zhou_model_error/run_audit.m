function result=run_audit(project)
%RUN_AUDIT Execute/reuse verified 24-case trajectories and finish attribution.
assert(isfile(fullfile(project.dirs.summary,'baseline_comparison.csv')), ...
    'ZhouModelError:BaselineMissing','Run baseline mode before audit mode.');
baseline=readtable(fullfile(project.dirs.summary,'baseline_comparison.csv'));assert(all(baseline.pass),'ZhouModelError:BaselineNotPassed');
scenarios=sequence_scenarios(project);assert(numel(scenarios)==24,'ZhouModelError:ScenarioCount');
sampleCells=cell(numel(scenarios),1);candidateCells=cell(numel(scenarios),1);
pAuditCells=cell(numel(scenarios),1);cAuditCells=cell(numel(scenarios),1);caseRows=repmat(case_template(),numel(scenarios),1);
for k=1:numel(scenarios)
    s=scenarios(k);checkpoint=fullfile(project.dirs.raw,'mat',char(s.scenario_id+"_model_error.mat"));loaded=false;
    if project.model_error.reuse_verified_case_cache&&isfile(checkpoint)
        Q=load(checkpoint,'audit_version','scenario','samples','candidate_detail','predictor_audit','candidate_audit','case_row');
        loaded=isfield(Q,'audit_version')&&string(Q.audit_version)==project.model_error.audit_version&& ...
            isfield(Q,'scenario')&&string(Q.scenario.scenario_id)==string(s.scenario_id)&& ...
            isfield(Q,'samples')&&all(ismember(["id_pred_P0","id_pred_P5","false_safe_P0"],string(Q.samples.Properties.VariableNames)));
    end
    if loaded
        samples=Q.samples;candidate_detail=Q.candidate_detail;predictor_audit=Q.predictor_audit;candidate_audit=Q.candidate_audit;case_row=Q.case_row;
        fprintf('[%02d/%02d] reused verified %s (%d samples)\n',k,numel(scenarios),s.scenario_id,height(samples));
    else
        fprintf('[%02d/%02d] simulating %s ...\n',k,numel(scenarios),s.scenario_id);
        simulation=zhou_robust.run_robust_case(project,s,"C0_original_feasibility_control",struct(),struct());
        [samples,predictor_audit]=zhou_model_error.decompose_simulation(project,simulation);
        [candidate_detail,candidate_audit]=zhou_model_error.offline_candidate_audit(project,simulation,samples);
        case_row=make_case_row(s,simulation,samples);
        scenario=s;audit_version=project.model_error.audit_version; %#ok<NASGU>
        save(checkpoint,'audit_version','scenario','simulation','samples','candidate_detail','predictor_audit','candidate_audit','case_row','-v7.3');
        fprintf('[%02d/%02d] completed %s (%d samples)\n',k,numel(scenarios),s.scenario_id,height(samples));
    end
    sampleCells{k}=samples;candidateCells{k}=candidate_detail;pAuditCells{k}=predictor_audit;cAuditCells{k}=candidate_audit;caseRows(k)=case_row;
end
T=vertcat(sampleCells{:});C=vertcat(candidateCells{:});pAudit=vertcat(pAuditCells{:});cAudit=vertcat(cAuditCells{:});caseInfo=struct2table(caseRows,'AsArray',true);
assert(height(T)==24153,'ZhouModelError:FrozenSampleCount','Expected 24153 samples; obtained %d.',height(T));
writetable(T,fullfile(project.dirs.raw,'model_error_samples.csv'));
save(fullfile(project.dirs.raw,'mat','combined_model_error_data.mat'),'T','C','caseInfo','pAudit','cAudit','-v7.3');
writetable(caseInfo,fullfile(project.dirs.summary,'simulation_case_summary.csv'));
writetable(struct2table(pAudit,'AsArray',true),fullfile(project.dirs.summary,'predictor_assertion_audit.csv'));
writetable(struct2table(cAudit,'AsArray',true),fullfile(project.dirs.summary,'candidate_convergence_audit.csv'));
S=zhou_model_error.build_summaries(project,T,C,caseInfo,pAudit,cAudit);
decision=zhou_model_error.make_decision(project,T,S);
figures=zhou_model_error.generate_figures(project,T,S,C);
if isfile(fullfile(project.root,'src','+zhou_model_error','generate_documentation.m'))
    docs=zhou_model_error.generate_documentation(project,T,S,decision,caseInfo,figures);
else
    docs=struct('generated',false,'reason',"documentation generator unavailable");
end
result=struct('case_count',numel(scenarios),'sample_count',height(T),'common_sample_count',nnz(T.oracle_previous_valid), ...
    'P0_false_safe_rate',mean(T.false_safe_P0),'P5_false_safe_rate',mean(T.false_safe_P5), ...
    'decision_code',decision.decision_code(1),'decision_label',decision.decision_label(1), ...
    'figures_generated',nnz(figures.generated),'documentation',docs);
save(fullfile(project.dirs.summary,'audit_outcome.mat'),'result','decision','-v7.3');
end

function r=make_case_row(s,simulation,T)
r=case_template();r.case_id=string(s.scenario_id);r.case_category=string(s.case_category);r.range_class=string(s.range_class);
r.speed_rpm=s.speed_rpm;r.id_ref_A=s.id_ref_A;r.iq_ref_A=s.iq_ref_A;r.dc_bus_V=s.dc_bus_V;r.profile_type=string(s.profile_type);
r.plant_Ld_scale=s.plant_Ld_scale;r.plant_Lq_scale=s.plant_Lq_scale;r.completed=simulation.completed;r.illegal_event=simulation.illegal_event.occurred;
r.trace_rows=height(simulation.trace);r.effective_samples=height(T);r.truncated=~simulation.completed;
r.in_primary_conclusion=string(s.range_class)~="stress_test";r.steady_spectrum_eligible=simulation.completed&&nnz(T.phase=="steady")>=500&&s.speed_rpm>=300;
r.S2_cycles=nnz(T.S2_triggered);r.P0_false_safe_count=nnz(T.false_safe_P0);r.P0_false_safe_rate=mean(T.false_safe_P0);
r.P5_replay_max_gap_A=max(T.P5_replay_gap_A);r.notes="";
if r.truncated,r.notes="pre-termination dynamic evidence only; excluded from steady spectrum";end
if startsWith(r.case_id,"D04")||startsWith(r.case_id,"D05"),r.notes=strjoin([r.notes,"torque reference is mapped from dq current, not an independent mechanical outer loop"],"; ");end
end

function r=case_template()
r=struct('case_id',"",'case_category',"",'range_class',"",'speed_rpm',NaN,'id_ref_A',NaN,'iq_ref_A',NaN, ...
    'dc_bus_V',NaN,'profile_type',"",'plant_Ld_scale',NaN,'plant_Lq_scale',NaN,'completed',false, ...
    'illegal_event',false,'trace_rows',0,'effective_samples',0,'truncated',false,'in_primary_conclusion',false, ...
    'steady_spectrum_eligible',false,'S2_cycles',0,'P0_false_safe_count',0,'P0_false_safe_rate',NaN, ...
    'P5_replay_max_gap_A',NaN,'notes',"");
end
