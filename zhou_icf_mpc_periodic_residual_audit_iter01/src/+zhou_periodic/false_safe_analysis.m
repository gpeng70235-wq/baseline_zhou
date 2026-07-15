function false_safe_analysis(cfg,T,W,split)
%FALSE_SAFE_ANALYSIS Held-out phase bins and matched event-centered windows.
fprintf('Phase 6: held-out false-safe association (descriptive, non-causal)...\n');
binRows=repmat(empty_bin(),0,1);eventRows=repmat(empty_event(),0,1);
valid=W(W.valid_for_order_tracking,:);
allPrimary=table();
for k=1:height(valid)
    cid=valid.case_id(k);c=T(T.case_id==cid,:);
    calS=split(split.case_id==cid & split.split=="calibration",:);
    valS=split(split.case_id==cid & split.split=="validation",:);
    cal=cycle_rows(c,calS);val=cycle_rows(c,valS);
    if isempty(cal)||isempty(val),continue;end
    coef=fit_all(cal);
    if valid.evidence_role(k)=="ENGINEERING_PRIMARY",allPrimary=[allPrimary;add_case_tag(val,cid,coef)];end %#ok<AGROW>
    for order=cfg.preregistered_orders
        [arg,domAxis]=phase_argument(val.electrical_angle,coef,order);
        fs=logical(val.false_safe);R=phase_R(arg(fs));
        edges=linspace(0,2*pi,cfg.phase_bin_count+1);[~,~,bin]=histcounts(arg,edges);
        for b=1:cfg.phase_bin_count
            m=bin==b;r=empty_bin();r.case_id=cid;r.evidence_role=valid.evidence_role(k);
            r.order=order;r.dominant_axis=domAxis;r.bin_index=b;r.phase_start=edges(b);r.phase_end=edges(b+1);
            r.sample_count=nnz(m);r.false_safe_count=nnz(fs&m);r.non_false_safe_count=nnz(~fs&m);
            r.false_safe_rate=r.false_safe_count/max(r.sample_count,1);r.event_phase_resultant_R=R;
            r.total_false_safe_events=nnz(fs);r.valid=nnz(fs)>0;binRows(end+1,1)=r; %#ok<AGROW>
        end
    end
    eventRows=[eventRows;event_windows(cfg,c,val,coef,valid.evidence_role(k))]; %#ok<AGROW>
end

% Add pooled primary phase bins using coefficients fitted within each case,
% never by pooling validation residuals into a new fit.
if ~isempty(allPrimary)
    for order=cfg.preregistered_orders
        arg=allPrimary.("phase"+order);fs=logical(allPrimary.false_safe);edges=linspace(0,2*pi,cfg.phase_bin_count+1);
        [~,~,bin]=histcounts(arg,edges);R=phase_R(arg(fs));
        for b=1:cfg.phase_bin_count
            m=bin==b;r=empty_bin();r.case_id="__ALL_PRIMARY__";r.evidence_role="ENGINEERING_PRIMARY_POOLED";
            r.order=order;r.dominant_axis="case_specific";r.bin_index=b;r.phase_start=edges(b);r.phase_end=edges(b+1);
            r.sample_count=nnz(m);r.false_safe_count=nnz(fs&m);r.non_false_safe_count=nnz(~fs&m);
            r.false_safe_rate=r.false_safe_count/max(r.sample_count,1);r.event_phase_resultant_R=R;
            r.total_false_safe_events=nnz(fs);r.valid=nnz(fs)>0;binRows(end+1,1)=r; %#ok<AGROW>
        end
    end
end
B=struct2table(binRows,'AsArray',true);E=struct2table(eventRows,'AsArray',true);
zhou_periodic.write_table(B,fullfile(cfg.summary_dir,'false_safe_phase_bins.csv'));
zhou_periodic.write_table(E,fullfile(cfg.summary_dir,'event_window_metrics.csv'));
write_report(cfg,B,E);
end

function tagged=add_case_tag(val,cid,coef)
tagged=val(:,{'false_safe'});tagged.case_id=repmat(cid,height(val),1);
[tagged.phase6,~]=phase_argument(val.electrical_angle,coef,6);
[tagged.phase12,~]=phase_argument(val.electrical_angle,coef,12);
end

function rows=event_windows(cfg,c,val,coef,role)
rows=repmat(empty_event(),0,1);events=find(val.false_safe);controls=find(~val.false_safe);
if isempty(events)||isempty(controls),return;end
matched=zeros(numel(events),1);
for j=1:numel(events)
    pool=controls(val.S2_triggered(controls)==val.S2_triggered(events(j)));
    if isempty(pool),pool=controls;end
    [~,ix]=min(abs(val.boundary_margin_A2(pool)-val.boundary_margin_A2(events(j))));matched(j)=pool(ix);
end
for cohort=["false_safe","matched_control"]
    if cohort=="false_safe",centers=val.sample_index(events);else,centers=val.sample_index(matched);end
    for off=-cfg.event_pre_samples:cfg.event_post_samples
        parts=cell(numel(centers),1);
        for j=1:numel(centers),parts{j}=c(c.sample_index==centers(j)+off,:);end
        parts=parts(~cellfun(@isempty,parts));if isempty(parts),continue;end
        A=vertcat(parts{:});p6=predict_order(A.electrical_angle,coef,6);p12=predict_order(A.electrical_angle,coef,12);
        r=empty_event();r.case_id=c.case_id(1);r.evidence_role=role;r.cohort=cohort;r.offset_samples=off;
        r.event_count=height(A);r.mean_e_d=mean(A.e_d);r.mean_e_q=mean(A.e_q);
        r.mean_residual_magnitude=mean(A.residual_magnitude);r.mean_periodic_6_magnitude=mean(hypot(p6(:,1),p6(:,2)));
        r.mean_periodic_12_magnitude=mean(hypot(p12(:,1),p12(:,2)));
        r.mean_Jd_boundary_distance=mean(A.distance_to_Jd_boundary);r.mean_Jq_boundary_distance=mean(A.distance_to_Jq_boundary);
        r.mean_voltage_utilization=mean(A.voltage_utilization);r.S2_fraction=mean(A.S2_triggered);r.false_safe_fraction=mean(A.false_safe);
        rows(end+1,1)=r; %#ok<AGROW>
    end
end
end

function coef=fit_all(A)
X=[cos(6*A.electrical_angle),sin(6*A.electrical_angle),cos(12*A.electrical_angle),sin(12*A.electrical_angle)];
coef.d=X\A.e_d;coef.q=X\A.e_q;
end
function P=predict_order(theta,coef,order)
if order==6,ix=1:2;else,ix=3:4;end
X=[cos(order*theta),sin(order*theta)];P=[X*coef.d(ix),X*coef.q(ix)];
end
function [arg,axis]=phase_argument(theta,coef,order)
if order==6,ix=1:2;else,ix=3:4;end
ad=hypot(coef.d(ix(1)),coef.d(ix(2)));aq=hypot(coef.q(ix(1)),coef.q(ix(2)));
if ad>=aq,b=coef.d(ix);axis="d";else,b=coef.q(ix);axis="q";end
phi=atan2(-b(2),b(1));arg=mod(order*theta+phi,2*pi);
end
function R=phase_R(x)
if isempty(x),R=NaN;else,R=abs(mean(exp(1i*x)));end
end
function A=cycle_rows(c,sr)
mask=false(height(c),1);for k=1:height(sr),mask=mask|(c.electrical_angle>=sr.theta_start(k)&c.electrical_angle<sr.theta_end(k));end
A=c(mask,:);
end
function r=empty_bin()
r=struct('case_id',"",'evidence_role',"",'order',0,'dominant_axis',"",'bin_index',0, ...
    'phase_start',NaN,'phase_end',NaN,'sample_count',0,'false_safe_count',0, ...
    'non_false_safe_count',0,'false_safe_rate',NaN,'event_phase_resultant_R',NaN, ...
    'total_false_safe_events',0,'valid',false);
end
function r=empty_event()
r=struct('case_id',"",'evidence_role',"",'cohort',"",'offset_samples',0,'event_count',0, ...
    'mean_e_d',NaN,'mean_e_q',NaN,'mean_residual_magnitude',NaN, ...
    'mean_periodic_6_magnitude',NaN,'mean_periodic_12_magnitude',NaN, ...
    'mean_Jd_boundary_distance',NaN,'mean_Jq_boundary_distance',NaN, ...
    'mean_voltage_utilization',NaN,'S2_fraction',NaN,'false_safe_fraction',NaN);
end
function write_report(cfg,B,E)
P=B(B.case_id=="__ALL_PRIMARY__",:);r6=unique(P.event_phase_resultant_R(P.order==6));r12=unique(P.event_phase_resultant_R(P.order==12));
if isempty(r6),r6=NaN;end;if isempty(r12),r12=NaN;end
caseSummary=B(B.evidence_role=="ENGINEERING_PRIMARY" & B.bin_index==1,:);
n6=nnz(caseSummary.order==6 & caseSummary.total_false_safe_events>=3 & caseSummary.event_phase_resultant_R>=0.5);
n12=nnz(caseSummary.order==12 & caseSummary.total_false_safe_events>=3 & caseSummary.event_phase_resultant_R>=0.5);
L=["# False-Safe Association Report";""; ...
    "This is a held-out descriptive association audit, not a causal claim. Harmonic coefficients are fitted only on calibration cycles; phase bins and event windows use validation cycles.";""; ...
    "## Matching";""; ...
    "Each validation false-safe event is matched within the same case to a non-false-safe sample with the same S2 state when available and the nearest Jd/Jq boundary margin. Event-centered windows span `k-"+cfg.event_pre_samples+"` to `k+"+cfg.event_post_samples+"`.";""; ...
    "## Results";""; ...
    "- Pooled primary event-phase resultant R: 6th `"+sprintf('%.6f',r6(1))+"`; 12th `"+sprintf('%.6f',r12(1))+"`."; ...
    "- Primary cases with >=3 events and case-level R >=0.5: 6th **"+n6+"**; 12th **"+n12+"**."; ...
    "- Event-window aggregate rows: **"+height(E)+"**.";""; ...
    "Speed, parameter cohort, S2 state, voltage utilization, and boundary distances remain explicit columns. A phase concentration alone is never labeled causation."];
writelines(L,fullfile(cfg.docs_dir,'FALSE_SAFE_ASSOCIATION_REPORT.md'),'Encoding','UTF-8');
end
