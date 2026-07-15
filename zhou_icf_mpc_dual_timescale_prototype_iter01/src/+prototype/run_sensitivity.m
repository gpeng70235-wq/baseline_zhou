function result=run_sensitivity(project)
gate=readtable(fullfile(project.dirs.summary,'prototype_gate_results.csv'),'TextType','string');
assert(all(logical(gate.pass))&&isfile(fullfile(project.dirs.summary,'method_metrics.csv')), ...
    'Prototype:SensitivityProhibited','Sensitivity is prohibited until the full campaign is complete.');
result=struct('status',"NOT_IMPLEMENTED_WITHOUT_FULL_GATE");
end
