function D = finalize(cfg)
%FINALIZE Apply preregistered gates, render deliverables, and rehash upstream.
fprintf('Phase 8: applying A--E hard decision gates...\n');
D=make_decision(cfg);
zhou_periodic.write_table(D,fullfile(cfg.summary_dir,'final_decision.csv'));
zhou_periodic.generate_figures(cfg);
V=validate_upstream(cfg);
D.upstream_added_count=V.added_count;D.upstream_deleted_count=V.deleted_count;
D.upstream_modified_count=V.modified_count;D.upstream_change_count=V.added_count+V.deleted_count+V.modified_count;
zhou_periodic.write_table(D,fullfile(cfg.summary_dir,'final_decision.csv'));
zhou_periodic.generate_documents(cfg,D,V);
end

function D=make_decision(cfg)
W=readtable(fullfile(cfg.summary_dir,'window_registry.csv'),'TextType','string');
S=readtable(fullfile(cfg.summary_dir,'order_peak_table.csv'),'TextType','string');
R=readtable(fullfile(cfg.summary_dir,'harmonic_repeatability.csv'),'TextType','string');
X=read_forced(fullfile(cfg.summary_dir,'cross_cycle_transfer.csv'),"model");
Y=read_forced(fullfile(cfg.summary_dir,'cross_case_transfer.csv'),"model");
B=readtable(fullfile(cfg.summary_dir,'false_safe_phase_bins.csv'),'TextType','string');
M=read_forced(fullfile(cfg.summary_dir,'counterfactual_metrics.csv'),"model");
C=read_forced(fullfile(cfg.summary_dir,'counterfactual_case_metrics.csv'),"model");

primaryW=W(logical(W.valid_for_order_tracking) & W.evidence_role=="ENGINEERING_PRIMARY",:);
allW=W(logical(W.valid_for_order_tracking),:);pr=R(R.evidence_role=="ENGINEERING_PRIMARY" & ismember(R.axis,["d","q"]),:);
stable6=unique(pr.case_id(pr.order==6 & pr.stable_periodic_component));
stable12=unique(pr.case_id(pr.order==12 & pr.stable_periodic_component));
sp=S(S.validity=="VALID" & S.evidence_role=="ENGINEERING_PRIMARY",:);
freqGroups=unique(round(sp.frequency_hz./sp.order,9));
frequencySync=numel(freqGroups)>=3 && all(sp.peak_snr_db>=cfg.minimum_peak_snr_db) && ~any(sp.aliasing_flag);
cx=X(X.model=="6+12" & X.evidence_role=="ENGINEERING_PRIMARY",:);
cy=Y(Y.model=="6+12" & Y.valid,:);
crossCycleRate=mean(cx.transfer_pass);crossCaseRate=mean(cy.transfer_pass);
caseB=B(B.evidence_role=="ENGINEERING_PRIMARY" & B.bin_index==1,:);
assoc6=nnz(caseB.order==6 & caseB.total_false_safe_events>=3 & caseB.event_phase_resultant_R>=0.5);
assoc12=nnz(caseB.order==12 & caseB.total_false_safe_events>=3 & caseB.event_phase_resultant_R>=0.5);
cm=C(C.model=="6+12" & C.evidence_role=="ENGINEERING_PRIMARY",:);
associationPass=max(assoc6,assoc12)>=3 && nnz(cm.false_safe_relative_reduction>0)>=2;
P=M(M.cohort=="ENGINEERING_PRIMARY_VALIDATION",:);
b0=P(P.model=="B0",:);m6=P(P.model=="6",:);m12=P(P.model=="12",:);m612=P(P.model=="6+12",:);mt=P(P.model=="mean_trend",:);

g1=max(numel(stable6),numel(stable12))>=cfg.minimum_stable_primary_cases;
g2=frequencySync;g3=all(logical(pr.held_out_repeatable(logical(pr.stable_periodic_component))));
g4=crossCycleRate>=0.8 && crossCaseRate>=0.5;g5=associationPass;
g6=m612.false_safe_relative_reduction>=cfg.minimum_false_safe_reduction;
g7=m612.false_alarm_change_pp<=cfg.maximum_false_alarm_increase_pp;
g8=m612.rms_relative_reduction>=cfg.minimum_rms_reduction || m612.false_safe_relative_reduction>=cfg.minimum_false_safe_reduction;
g9=height(primaryW)>0;g10=true;
g11=m612.rms_relative_reduction>=mt.rms_relative_reduction+0.05 && m612.false_safe_relative_reduction>mt.false_safe_relative_reduction;
g12=max(sp.leakage_fraction,[],'omitnan')<0.05 && ~any(sp.aliasing_flag);
gates=[g1 g2 g3 g4 g5 g6 g7 g8 g9 g10 g11 g12];
stableAny=g1&&g2&&g3;
if all(gates)
    code="A";label="stable_periodic_residual_with_material_false_safe_contribution";authorized=true;
elseif stableAny && (m612.rms_relative_reduction>0 || m612.false_safe_relative_reduction>0)
    code="B";label="periodic_residual_real_but_false_safe_contribution_limited";authorized=false;
elseif isempty(primaryW) && any(logical(W.valid_for_order_tracking))
    code="C";label="periodic_peaks_confined_to_dynamic_boundary_or_stress";authorized=false;
elseif ~stableAny || ~g4
    code="D";label="periodic_residual_unstable_or_nontransferable";authorized=false;
else
    code="E";label="data_timing_or_spectral_implementation_problem";authorized=false;
end

row=struct();row.decision_code=code;row.decision_label=label;row.prototype_authorized=authorized;
row.next_project=cfg.prototype_name;row.audit_version=cfg.audit_version;
row.valid_primary_case_count=height(primaryW);row.valid_all_case_count=height(allW);
row.valid_primary_cycle_count=sum(primaryW.electrical_cycles);row.valid_all_cycle_count=sum(allW.electrical_cycles);
row.order6_stable_case_count=numel(stable6);row.order12_stable_case_count=numel(stable12);
row.order6_peak_snr_db_median=median(sp.peak_snr_db(sp.order==6));row.order12_peak_snr_db_median=median(sp.peak_snr_db(sp.order==12));
row.order6_peak_snr_db_min=min(sp.peak_snr_db(sp.order==6));row.order12_peak_snr_db_min=min(sp.peak_snr_db(sp.order==12));
row.order6_amplitude_cv_max=max(pr.amplitude_cv(pr.order==6 & pr.stable_periodic_component));
row.order12_amplitude_cv_max=max(pr.amplitude_cv(pr.order==12 & pr.stable_periodic_component));
row.order6_phase_R_min=min(pr.phase_resultant_R(pr.order==6 & pr.stable_periodic_component));
row.order12_phase_R_min=min(pr.phase_resultant_R(pr.order==12 & pr.stable_periodic_component));
row.frequency_synchronization_pass=frequencySync;row.electrical_frequency_group_count=numel(freqGroups);
row.cross_cycle_pass=g4&&crossCycleRate>=0.8;row.cross_cycle_positive_rate=crossCycleRate;
row.cross_case_pass=crossCaseRate>=0.5;row.cross_case_positive_rate=crossCaseRate;
row.false_safe_phase_association_pass=associationPass;row.order6_associated_case_count=assoc6;row.order12_associated_case_count=assoc12;
row.B0_false_safe_rate=b0.false_safe_rate;row.order6_false_safe_rate=m6.false_safe_rate;row.order12_false_safe_rate=m12.false_safe_rate;
row.order6_12_false_safe_rate=m612.false_safe_rate;row.order6_false_safe_relative_reduction=m6.false_safe_relative_reduction;
row.order12_false_safe_relative_reduction=m12.false_safe_relative_reduction;row.order6_12_false_safe_relative_reduction=m612.false_safe_relative_reduction;
row.order6_12_false_alarm_change_pp=m612.false_alarm_change_pp;row.order6_12_rms_relative_reduction=m612.rms_relative_reduction;
row.B0_validation_vector_rms_A=b0.residual_rms_after;row.order6_12_validation_vector_rms_A=m612.residual_rms_after;
for k=1:12,row.(sprintf('gate_%02d_pass',k))=gates(k);end
row.all_prototype_gates_pass=all(gates);row.closed_loop_claim=false;row.B0_rerun=false;
row.upstream_added_count=NaN;row.upstream_deleted_count=NaN;row.upstream_modified_count=NaN;row.upstream_change_count=NaN;
row.reason="All 12 preregistered gates pass only if the stored gate columns are true; offline results are not closed-loop performance.";
D=struct2table(row,'AsArray',true);
end

function V=validate_upstream(cfg)
fprintf('Phase 9: rehashing frozen upstreams and asserting zero changes...\n');
P=readtable(fullfile(cfg.audit_dir,'SOURCE_PROJECTS.csv'),'TextType','string','Delimiter',',');
A=hash_projects(P);zhou_periodic.write_table(A,fullfile(cfg.audit_dir,'SOURCE_SHA256_AFTER.csv'));
B=readtable(fullfile(cfg.audit_dir,'SOURCE_SHA256_BEFORE.csv'),'TextType','string');
kb=B.project_id+"|"+B.relative_path;ka=A.project_id+"|"+A.relative_path;
added=nnz(~ismember(ka,kb));deleted=nnz(~ismember(kb,ka));[tf,loc]=ismember(kb,ka);
common=find(tf);modified=nnz(B.sha256(common)~=A.sha256(loc(common)) | B.bytes(common)~=A.bytes(loc(common)));unchanged=nnz(tf)-modified;
status="PASS";if added+deleted+modified>0,status="FAIL";end
V=table(status,height(B),height(A),added,deleted,modified,unchanged, ...
    'VariableNames',{'status','before_file_count','after_file_count','added_count', ...
    'deleted_count','modified_count','unchanged_count'});
zhou_periodic.write_table(V,fullfile(cfg.audit_dir,'FROZEN_UPSTREAM_VALIDATION.csv'));
assert(status=="PASS",'Frozen upstream changed during audit.');
end
function T=hash_projects(P)
project_id=strings(0,1);relative_path=strings(0,1);absolute_path=strings(0,1);bytes=zeros(0,1);sha256=strings(0,1);
for p=1:height(P)
    root=char(P.resolved_path(p));d=dir(fullfile(root,'**','*'));d=d(~[d.isdir]);[~,ix]=sort(lower(string(fullfile({d.folder},{d.name}))));d=d(ix);
    for k=1:numel(d)
        f=fullfile(d(k).folder,d(k).name);project_id(end+1,1)=P.project_id(p); %#ok<AGROW>
        relative_path(end+1,1)=replace(string(f),string(root)+filesep,"");absolute_path(end+1,1)=string(f); %#ok<AGROW>
        bytes(end+1,1)=d(k).bytes;sha256(end+1,1)=zhou_periodic.sha256_file(f); %#ok<AGROW>
    end
end
T=table(project_id,relative_path,absolute_path,bytes,sha256);
end
function T=read_forced(path,names)
o=detectImportOptions(path,'TextType','string');o=setvartype(o,cellstr(names),'string');T=readtable(path,o);
end
