function [catalog,clusters,association,audit] = classify_residual_events(trace,options)
%CLASSIFY_RESIDUAL_EVENTS Apply one consistent d/q residual-event contract.
% Adjacent event samples are clustered separately by scenario and axis.

arguments
    trace table
    options struct = struct()
end
assert(height(trace)>0,'ZhouValidation:EventTrace', ...
    'Residual-event classification requires a nonempty trace.');
cfg=event_options(options);
n=height(trace);
cycle=column_or(trace,"cycle_index",(1:n).');
scenario=scenario_column(trace,n);

d_error=column_required(trace, ...
    ["prediction_error_d_A" "d_prediction_error"]);
q_error=column_required(trace, ...
    ["prediction_error_q_A" "q_prediction_error"]);
d_exceed=column_required(trace, ...
    ["actual_exceedance_d_A" "d_actual_exceedance"]);
q_exceed=column_required(trace, ...
    ["actual_exceedance_q_A" "q_actual_exceedance"]);

catalog=build_axis_catalog(trace,scenario,cycle,d_error,d_exceed,"d",cfg);
q_catalog=build_axis_catalog(trace,scenario,cycle,q_error,q_exceed,"q",cfg);
catalog=[catalog;q_catalog];
if ~isempty(catalog)
    catalog.event_id=(1:height(catalog)).';
    catalog.cluster_id=assign_clusters(catalog.scenario_id,catalog.axis, ...
        catalog.event_cycle_index);
else
    catalog.event_id=zeros(0,1);catalog.cluster_id=zeros(0,1);
end
clusters=summarize_clusters(catalog,cfg.context_cycles);

case_flag=logical_column(trace,["case_transition" "case_transition_flag"],n);
sector_flag=logical_column(trace,["sector_transition" "sector_transition_flag"],n);
command_flag=logical_column(trace, ...
    ["command_transition" "command_changed_flag"],n);
duration_change=duration_change_column(trace);
duration_cutoff=quantile_local(duration_change,cfg.duration_quantile);
duration_flag=duration_change>duration_cutoff;
conditions=struct('case_transition',case_flag, ...
    'sector_transition',sector_flag,'command_transition',command_flag, ...
    'duration_p95',duration_flag, ...
    'stable',~case_flag & ~sector_flag & ~command_flag & ~duration_flag);
association=association_table(d_error,q_error,d_exceed,q_exceed, ...
    conditions,cfg);

audit=struct();
audit.definition_version="1.0";
audit.engineering_exceedance_A=cfg.engineering_exceedance_A;
audit.prediction_level_thresholds_A=cfg.level_thresholds_A;
audit.extreme_prediction_A=cfg.extreme_prediction_A;
audit.extreme_exceedance_A=cfg.extreme_exceedance_A;
audit.context_cycles=cfg.context_cycles;
audit.duration_quantile=cfg.duration_quantile;
audit.duration_cutoff=duration_cutoff;
audit.total_source_rows=n;
audit.event_rows=height(catalog);
audit.clusters=height(clusters);
audit.same_event_mask_used_for_catalog_and_association=true;
end

function C=build_axis_catalog(T,scenario,cycle,error_A,exceed_A,axis,cfg)
abs_error=abs(error_A);
mask=abs_error>cfg.level_thresholds_A(1) | ...
    exceed_A>cfg.engineering_exceedance_A;
C=T(mask,:);
C.source_row=find(mask);
C.scenario_id=scenario(mask);
C.event_cycle_index=cycle(mask);
C.axis=repmat(axis,nnz(mask),1);
C.prediction_error_A=error_A(mask);
C.absolute_prediction_error_A=abs_error(mask);
C.actual_exceedance_A=exceed_A(mask);
level=repmat("level1",nnz(mask),1);
level(abs_error(mask)>cfg.level_thresholds_A(2))="level2";
level(abs_error(mask)>cfg.level_thresholds_A(3))="level3";
extreme=abs_error(mask)>cfg.extreme_prediction_A | ...
    exceed_A(mask)>cfg.extreme_exceedance_A;
level(extreme)="extreme";
C.event_level=level;
C.extreme_event=extreme;
C.context_start_cycle=max(C.event_cycle_index-cfg.context_cycles,1);
C.context_end_cycle=C.event_cycle_index+cfg.context_cycles;
end

function ids=assign_clusters(scenario,axis,cycle)
ids=zeros(numel(cycle),1);cluster=0;last_cycle=-Inf;last_scenario="";last_axis="";
for k=1:numel(cycle)
    if k==1 || scenario(k)~=last_scenario || axis(k)~=last_axis || ...
            cycle(k)>last_cycle+1
        cluster=cluster+1;
    end
    ids(k)=cluster;last_cycle=cycle(k);last_scenario=scenario(k);last_axis=axis(k);
end
end

function S=summarize_clusters(C,context_cycles)
if isempty(C)
    S=table(strings(0,1),strings(0,1),zeros(0,1),zeros(0,1), ...
        zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1), ...
        false(0,1),'VariableNames',{'scenario_id','axis','cluster_id', ...
        'event_count','first_cycle','last_cycle','cluster_span_cycles', ...
        'peak_prediction_error_A','peak_actual_exceedance_A','has_extreme'});
    return
end
ids=unique(C.cluster_id,'stable');rows=cell(numel(ids),10);
for k=1:numel(ids)
    G=C(C.cluster_id==ids(k),:);
    rows(k,:)={G.scenario_id(1),G.axis(1),ids(k),height(G), ...
        min(G.event_cycle_index),max(G.event_cycle_index), ...
        max(G.event_cycle_index)-min(G.event_cycle_index)+1, ...
        max(G.absolute_prediction_error_A),max(G.actual_exceedance_A), ...
        any(G.extreme_event)};
end
S=cell2table(rows,'VariableNames',{'scenario_id','axis','cluster_id', ...
    'event_count','first_cycle','last_cycle','cluster_span_cycles', ...
    'peak_prediction_error_A','peak_actual_exceedance_A','has_extreme'});
S.context_start_cycle=max(S.first_cycle-context_cycles,1);
S.context_end_cycle=S.last_cycle+context_cycles;
end

function A=association_table(de,qe,dx,qx,conditions,cfg)
condition_names=string(fieldnames(conditions));A=table();
for axis=["d" "q"]
    if axis=="d", error_A=de;exceed_A=dx; else, error_A=qe;exceed_A=qx; end
    event=abs(error_A)>cfg.level_thresholds_A(1) | ...
        exceed_A>cfg.engineering_exceedance_A;
    for k=1:numel(condition_names)
        name=condition_names(k);selected=conditions.(char(name));
        complement=~selected;count=nnz(selected);
        if count==0
            probability=NaN;mean_error=NaN;max_error=NaN; ...
                mean_exceed=NaN;max_exceed=NaN;
        else
            probability=mean(event(selected));
            mean_error=mean(abs(error_A(selected)),'omitnan');
            max_error=max(abs(error_A(selected)),[],'omitnan');
            mean_exceed=mean(exceed_A(selected),'omitnan');
            max_exceed=max(exceed_A(selected),[],'omitnan');
        end
        if nnz(complement)==0, base=NaN; else, base=mean(event(complement)); end
        if isnan(base) || base==0, risk=NaN; else, risk=probability/base; end
        row=table(axis,name,count,nnz(event & selected),probability, ...
            mean_error,max_error,mean_exceed,max_exceed,risk, ...
            'VariableNames',{'axis','transition_type','samples', ...
            'event_samples','conditional_probability','mean_abs_prediction_error_A', ...
            'max_abs_prediction_error_A','mean_actual_exceedance_A', ...
            'max_actual_exceedance_A','risk_ratio_vs_complement'});
        A=[A;row]; %#ok<AGROW>
    end
end
end

function cfg=event_options(value)
cfg=struct('engineering_exceedance_A',.01, ...
    'level_thresholds_A',[.05 .10 .20], ...
    'extreme_prediction_A',.25,'extreme_exceedance_A',.20, ...
    'context_cycles',8,'duration_quantile',.95);
names=fieldnames(value);
for k=1:numel(names), cfg.(names{k})=value.(names{k}); end
assert(numel(cfg.level_thresholds_A)==3 && ...
    issorted(cfg.level_thresholds_A) && all(cfg.level_thresholds_A>0), ...
    'ZhouValidation:EventThresholds','Expected three increasing levels.');
end

function value=column_required(T,candidates)
vars=string(T.Properties.VariableNames);idx=find(ismember(candidates,vars),1);
assert(~isempty(idx),'ZhouValidation:EventFields', ...
    'Missing required event field: one of %s.',strjoin(candidates,', '));
value=double(T.(char(candidates(idx))));value=value(:);
end

function value=column_or(T,candidates,default_value)
vars=string(T.Properties.VariableNames);idx=find(ismember(candidates,vars),1);
if isempty(idx), value=default_value; else, value=double(T.(char(candidates(idx)))); end
value=value(:);
end

function value=logical_column(T,candidates,n)
vars=string(T.Properties.VariableNames);idx=find(ismember(candidates,vars),1);
if isempty(idx), value=false(n,1); else, value=logical(T.(char(candidates(idx)))); end
value=value(:);
end

function scenario=scenario_column(T,n)
vars=string(T.Properties.VariableNames);
if ismember("scenario_id",vars), scenario=string(T.scenario_id);
elseif ismember("scenario",vars), scenario=string(T.scenario);
else, scenario=repmat("scenario",n,1);
end
scenario=scenario(:);
end

function change=duration_change_column(T)
vars=string(T.Properties.VariableNames);n=height(T);
if ismember("duration_change_norm",vars)
    change=double(T.duration_change_norm(:));return
end
if ismember("selected_durations_s",vars)
    raw=string(T.selected_durations_s);
elseif ismember("sequence_durations_s",vars)
    raw=string(T.sequence_durations_s);
else
    change=zeros(n,1);return
end
change=zeros(n,1);previous=[];
for k=1:n
    current=sscanf(char(raw(k)),'%f;').';
    if ~isempty(previous)
        count=max(numel(current),numel(previous));
        a=zeros(1,count);b=a;a(1:numel(current))=current;b(1:numel(previous))=previous;
        change(k)=sum(abs(a-b));
    end
    previous=current;
end
end

function q=quantile_local(x,p)
x=sort(x(isfinite(x)));
if isempty(x), q=NaN; return; end
if isscalar(x), q=x; return; end
position=1+(numel(x)-1)*p;lo=floor(position);hi=ceil(position);
q=x(lo)+(position-lo)*(x(hi)-x(lo));
end
