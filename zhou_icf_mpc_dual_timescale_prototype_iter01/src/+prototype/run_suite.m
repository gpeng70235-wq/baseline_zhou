function result = run_suite(project,scenario_ids,methods,repeats,tag,overrides)
%RUN_SUITE Cacheable deterministic campaign with unique per-task artifacts.
if nargin<6,overrides=struct();end
all_scenarios=sequence_scenarios(project);
mask=ismember(string({all_scenarios.scenario_id}),string(scenario_ids));
scenarios=all_scenarios(mask);assert(numel(scenarios)==numel(scenario_ids),'Prototype:ScenarioSelection');
methods=string(methods);tasks=struct('scenario',{},'method',{},'repeat',{},'cache',{});
for s=1:numel(scenarios)
    for m=1:numel(methods)
        for r=1:repeats
            q.scenario=scenarios(s);q.method=methods(m);q.repeat=r;
            q.cache=fullfile(project.dirs.cache,sprintf('%s_%s_%s_r%d.mat',tag,methods(m),scenarios(s).scenario_id,r));
            tasks(end+1)=q; %#ok<AGROW>
        end
    end
end
metric_cells=cell(numel(tasks),1);use_parallel=numel(tasks)>=8&&license('test','Distrib_Computing_Toolbox');
if use_parallel
    try
        pool=gcp('nocreate');if isempty(pool),parpool('local',min(4,numel(tasks)));end
    catch
        use_parallel=false;
    end
end
if use_parallel
    parfor k=1:numel(tasks)
        [metric_cells{k},~]=execute_task(project,tasks(k),overrides);
    end
else
    for k=1:numel(tasks)
        [metric_cells{k},~]=execute_task(project,tasks(k),overrides);
    end
end
case_metrics=vertcat(metric_cells{:});
repeat_col=[tasks.repeat].';case_metrics=addvars(case_metrics,repeat_col,'After','method','NewVariableNames','repeat');
writetable(case_metrics,fullfile(project.dirs.summary,tag+"_case_metrics.csv"));
repeatability=build_repeatability(tasks);
writetable(repeatability,fullfile(project.dirs.summary,tag+"_repeatability.csv"));
rep1=case_metrics(case_metrics.repeat==1,:);
method_metrics=prototype.aggregate_metrics(rep1,"method");
cohort_metrics=prototype.aggregate_metrics(rep1,"category");
writetable(method_metrics,fullfile(project.dirs.summary,tag+"_method_metrics.csv"));
writetable(cohort_metrics,fullfile(project.dirs.summary,tag+"_cohort_metrics.csv"));
for method=methods
    parts=cell(numel(scenarios),1);
    for s=1:numel(scenarios)
        cache=fullfile(project.dirs.cache,sprintf('%s_%s_%s_r1.mat',tag,method,scenarios(s).scenario_id));
        Q=load(cache,'simulation');parts{s}=Q.simulation.trace;
    end
    raw=vertcat(parts{:});writetable(raw,fullfile(project.dirs.raw,"closed_loop_samples_"+method+".csv"));
    est_names=intersect(raw.Properties.VariableNames,{'case_id','method','sample_index','time_s', ...
        'alpha_d','alpha_q','F_d','F_q','F_pred_d','F_pred_q','gate_exc_d','gate_exc_q', ...
        'gate_s2','gate_decision','alpha_update_d','alpha_update_q','freeze_reason_d', ...
        'freeze_reason_q','reset_event','u_hp_d','u_hp_q','y_hp_d','y_hp_q'},'stable');
    writetable(raw(:,est_names),fullfile(project.dirs.raw,"estimator_states_"+method+".csv"));
    dec_names=intersect(raw.Properties.VariableNames,{'case_id','method','sample_index','time_s', ...
        'pending_command_id','selected_core_id','selected_final_id','mode','selected_core', ...
        'selected_final','S2_triggered','Jd_pred','Jq_pred','Jd_actual','Jq_actual', ...
        'false_safe','false_alarm'},'stable');
    writetable(raw(:,dec_names),fullfile(project.dirs.raw,"control_decisions_"+method+".csv"));
end
result=struct('case_metrics',case_metrics,'method_metrics',method_metrics, ...
    'cohort_metrics',cohort_metrics,'repeatability',repeatability,'tag',tag);
end

function [metric,simulation]=execute_task(project,task,overrides)
if isfile(task.cache)
    Q=load(task.cache,'simulation');simulation=Q.simulation;
else
    fprintf('[%s] %s %s repeat %d\n',char(datetime('now','Format','HH:mm:ss')), ...
        task.method,task.scenario.scenario_id,task.repeat);
    simulation=prototype.run_control_case(project,task.scenario,task.method,overrides);
    repeat=task.repeat; %#ok<NASGU>
    save(task.cache,'simulation','repeat','-v7.3');
end
metric=simulation.summary;
end

function R=build_repeatability(tasks)
keys=unique(string({tasks.method}).'+"|"+string(arrayfun(@(x)x.scenario.scenario_id,tasks,'UniformOutput',false)).','stable');
rows=cell(numel(keys),1);
for k=1:numel(keys)
    ix=find(string({tasks.method}).'+"|"+string(arrayfun(@(x)x.scenario.scenario_id,tasks,'UniformOutput',false)).'==keys(k));
    base=load(tasks(ix(1)).cache,'simulation');numeric_delta=0;sequence_equal=true;
    for j=2:numel(ix)
        q=load(tasks(ix(j)).cache,'simulation');
        A=base.simulation.trace;B=q.simulation.trace;
        cols={'id','iq','alpha_d','alpha_q','F_d','F_q','Jd_pred','Jq_pred','false_safe','false_alarm'};
        for c=1:numel(cols)
            d=max(abs(double(A.(cols{c}))-double(B.(cols{c}))),[],'all','omitnan');
            if isempty(d)||isnan(d),d=0;end;numeric_delta=max(numeric_delta,d);
        end
        sequence_equal=sequence_equal&&isequal(A.selected_final_id,B.selected_final_id);
    end
    parts=split(keys(k),'|');rows{k}=table(parts(1),parts(2),numel(ix),numeric_delta,sequence_equal, ...
        numeric_delta<=1e-12&&sequence_equal,'VariableNames', ...
        {'method','case_id','repeat_count','max_numeric_delta','sequence_equal','pass'});
end
R=vertcat(rows{:});
end
