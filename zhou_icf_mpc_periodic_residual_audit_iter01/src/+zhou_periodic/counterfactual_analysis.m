function counterfactual_analysis(cfg,T,W,split,~)
%COUNTERFACTUAL_ANALYSIS Held-out offline constraint reclassification only.
fprintf('Phase 7: held-out offline counterfactual constraint classification...\n');
models=["B0","mean_trend","6","12","6+12"];
valid=W(W.valid_for_order_tracking,:);
caseRows=repmat(empty_metric(),0,1);sampleParts=cell(0,1);
for k=1:height(valid)
    cid=valid.case_id(k);c=T(T.case_id==cid,:);
    calS=split(split.case_id==cid & split.split=="calibration",:);
    valS=split(split.case_id==cid & split.split=="validation",:);
    A=cycle_rows(c,calS);B=cycle_rows(c,valS);
    for model=models
        [pd,pq]=periodic_prediction(A,B,model);
        Q=evaluate(cfg,B,pd,pq);Q.case_id=repmat(cid,height(Q),1);Q.model=repmat(model,height(Q),1);
        Q.evidence_role=repmat(valid.evidence_role(k),height(Q),1);Q.category=repmat(valid.category(k),height(Q),1);
        Q.range_class=repmat(valid.range_class(k),height(Q),1);sampleParts{end+1,1}=Q; %#ok<AGROW>
        r=metric_row(Q,"CASE:"+cid,model);r.case_id=cid;r.evidence_role=valid.evidence_role(k);
        r.category=valid.category(k);r.range_class=valid.range_class(k);caseRows(end+1,1)=r; %#ok<AGROW>
    end
end
samples=vertcat(sampleParts{:});C=struct2table(caseRows,'AsArray',true);
C=add_changes(C,{'case_id'});
zhou_periodic.write_table(C,fullfile(cfg.summary_dir,'counterfactual_case_metrics.csv'));

cohorts={ ...
    'ALL_VALIDATION',true(height(samples),1); ...
    'ENGINEERING_PRIMARY_VALIDATION',samples.evidence_role=="ENGINEERING_PRIMARY"; ...
    'CORE_VALIDATION',samples.evidence_role=="ENGINEERING_PRIMARY" & samples.category=="core"; ...
    'PARAMETER_VALIDATION',samples.evidence_role=="ENGINEERING_PRIMARY" & samples.category=="parameter"; ...
    'DYNAMIC_SECONDARY_VALIDATION',samples.evidence_role=="SECONDARY_DYNAMIC"; ...
    'NORMAL_VALIDATION',samples.evidence_role=="ENGINEERING_PRIMARY" & samples.range_class=="normal"; ...
    'REASONABLE_EXTENSION_VALIDATION',samples.evidence_role=="ENGINEERING_PRIMARY" & samples.range_class=="reasonable_extension"};
rows=repmat(empty_metric(),0,1);
for q=1:size(cohorts,1)
    for model=models
        m=cohorts{q,2} & samples.model==model;if ~any(m),continue;end
        r=metric_row(samples(m,:),string(cohorts{q,1}),model);
        caseSlice=C(C.model==model & ismember(C.case_id,unique(samples.case_id(cohorts{q,2}))),:);
        r.improved_case_count=nnz(caseSlice.rms_relative_reduction>0);
        r.false_safe_improved_case_count=nnz(caseSlice.false_safe_relative_reduction>0);
        r.effective_in_multiple_cases=r.false_safe_improved_case_count>=2;
        rows(end+1,1)=r; %#ok<AGROW>
    end
end
M=struct2table(rows,'AsArray',true);M=add_changes(M,{'cohort'});
zhou_periodic.write_table(M,fullfile(cfg.summary_dir,'counterfactual_metrics.csv'));
write_report(cfg,M,C);
end

function [pd,pq]=periodic_prediction(A,B,model)
if model=="B0",pd=zeros(height(B),1);pq=pd;return;end
if model=="mean_trend"
    center=mean(A.electrical_angle);XA=[ones(height(A),1),A.electrical_angle-center];
    XB=[ones(height(B),1),B.electrical_angle-center];pd=XB*(XA\A.e_d);pq=XB*(XA\A.e_q);return;
end
XA=design(A.electrical_angle,model);XB=design(B.electrical_angle,model);
pd=XB*(XA\A.e_d);pq=XB*(XA\A.e_q);
end
function X=design(theta,model)
if model=="6",orders=6;elseif model=="12",orders=12;else,orders=[6 12];end
X=zeros(numel(theta),2*numel(orders));for k=1:numel(orders),X(:,2*k-1:2*k)=[cos(orders(k)*theta),sin(orders(k)*theta)];end
end
function Q=evaluate(cfg,B,pd,pq)
Q=table();Q.sample_index=B.sample_index;Q.residual_before=hypot(B.e_d,B.e_q);
Q.residual_after=hypot(B.e_d-pd,B.e_q-pq);Q.id_pred_corrected=B.id_pred+pd;Q.iq_pred_corrected=B.iq_pred+pq;
Q.Jd_corrected=(B.id_ref-Q.id_pred_corrected).^2;Q.Jq_corrected=(B.iq_ref-Q.iq_pred_corrected).^2;
Q.predicted_pass_corrected=Q.Jd_corrected<=cfg.Jd_limit_A2+cfg.constraint_tolerance_A2 & ...
    Q.Jq_corrected<=cfg.Jq_limit_A2+cfg.constraint_tolerance_A2;
Q.false_safe=Q.predicted_pass_corrected & ~B.actual_joint_pass;
Q.false_alarm=~Q.predicted_pass_corrected & B.actual_joint_pass;
end
function r=metric_row(Q,cohort,model)
r=empty_metric();r.cohort=cohort;r.model=model;r.sample_count=height(Q);
r.residual_rms_before=rms(Q.residual_before);r.residual_rms_after=rms(Q.residual_after);
r.rms_relative_reduction=1-r.residual_rms_after/max(r.residual_rms_before,eps);
r.false_safe_count=nnz(Q.false_safe);r.false_safe_rate=mean(Q.false_safe);
r.false_alarm_count=nnz(Q.false_alarm);r.false_alarm_rate=mean(Q.false_alarm);
r.maximum_consecutive_false_safe=max_run_grouped(Q);
end
function T=add_changes(T,keys)
groups=unique(T(:,keys),'rows');
for k=1:height(groups)
    mask=true(height(T),1);for j=1:numel(keys),mask=mask&T.(keys{j})==groups.(keys{j})(k);end
    b=find(mask&T.model=="B0",1);if isempty(b),continue;end
    T.false_safe_relative_reduction(mask)= (T.false_safe_rate(b)-T.false_safe_rate(mask))/max(T.false_safe_rate(b),eps);
    T.false_safe_absolute_change_pp(mask)=100*(T.false_safe_rate(mask)-T.false_safe_rate(b));
    T.false_alarm_change_pp(mask)=100*(T.false_alarm_rate(mask)-T.false_alarm_rate(b));
end
end
function m=max_run_grouped(Q)
if ~ismember('case_id',Q.Properties.VariableNames),m=max_run(Q.false_safe);return;end
m=0;ids=unique(Q.case_id);for c=reshape(ids,1,[]),m=max(m,max_run(Q.false_safe(Q.case_id==c)));end
end
function m=max_run(x)
x=logical(x(:));d=diff([false;x;false]);starts=find(d==1);ends=find(d==-1)-1;
if isempty(starts),m=0;else,m=max(ends-starts+1);end
end
function A=cycle_rows(c,sr)
mask=false(height(c),1);for k=1:height(sr),mask=mask|(c.electrical_angle>=sr.theta_start(k)&c.electrical_angle<sr.theta_end(k));end
A=c(mask,:);
end
function r=empty_metric()
r=struct('cohort',"",'case_id',"",'evidence_role',"",'category',"",'range_class',"", ...
    'model',"",'sample_count',0,'residual_rms_before',NaN,'residual_rms_after',NaN, ...
    'rms_relative_reduction',NaN,'false_safe_count',0,'false_safe_rate',NaN, ...
    'false_safe_relative_reduction',NaN,'false_safe_absolute_change_pp',NaN, ...
    'false_alarm_count',0,'false_alarm_rate',NaN,'false_alarm_change_pp',NaN, ...
    'maximum_consecutive_false_safe',0,'improved_case_count',0, ...
    'false_safe_improved_case_count',0,'effective_in_multiple_cases',false);
end
function write_report(cfg,M,C)
P=M(M.cohort=="ENGINEERING_PRIMARY_VALIDATION",:);
L=["# Counterfactual Correction Report";""; ...
    "These results are **offline counterfactual constraint classification**, not closed-loop control performance. The original B0 trajectory, selected vectors, plant, limits, and S2 decisions are unchanged.";""; ...
    "## Isolation";""; ...
    "Coefficients are fitted only on the earlier complete calibration cycles of each case. Held-out actual currents are used solely to score residuals and actual constraint truth; they never tune the correction."; ...
    "The corrected predictions are `i_pred_B0 + e_periodic`, followed by recomputation of fixed `Jd/Jq=0.16 A^2` classifications.";""; ...
    "## ENGINEERING_PRIMARY held-out results";""];
for model=["B0","mean_trend","6","12","6+12"]
    r=P(P.model==model,:);if isempty(r),continue;end
    L(end+1)="- **"+model+"**: residual RMS `"+sprintf('%.9g',r.residual_rms_after)+" A`; RMS change `"+ ...
        sprintf('%+.3f%%',100*r.rms_relative_reduction)+"`; false-safe `"+sprintf('%.6f%%',100*r.false_safe_rate)+ ...
        "` (relative change `"+sprintf('%+.3f%%',-100*r.false_safe_relative_reduction)+"`); false-alarm change `"+ ...
        sprintf('%+.6f pp',r.false_alarm_change_pp)+"`; max FS run `"+r.maximum_consecutive_false_safe+"`."; %#ok<AGROW>
end
L=[L;"";"Per-case and cohort results are complete in the two registered counterfactual CSVs. A candidate bank was not reconstructed, so no offline ranking is presented as native Zhou decision behavior."; ...
    "Case-level rows: **"+height(C)+"**. Future validation data were not used for coefficient updates."];
writelines(L,fullfile(cfg.docs_dir,'COUNTERFACTUAL_CORRECTION_REPORT.md'),'Encoding','UTF-8');
end
