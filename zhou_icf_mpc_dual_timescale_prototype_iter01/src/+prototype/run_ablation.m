function result=run_ablation(project)
gate=readtable(fullfile(project.dirs.summary,'prototype_gate_results.csv'),'TextType','string');
assert(all(logical(gate.pass))&&isfile(fullfile(project.dirs.summary,'method_metrics.csv')), ...
    'Prototype:AblationProhibited','Ablation is prohibited until P completes the full 24-case campaign.');
result=struct('status',"NOT_IMPLEMENTED_WITHOUT_FULL_GATE");
end
