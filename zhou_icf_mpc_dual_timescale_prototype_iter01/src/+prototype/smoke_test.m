function result=smoke_test(project)
scenarios=sequence_scenarios(project);s=scenarios(1);s.simulation_time_s=.003;s.steady_window_start_s=.001;
rows=cell(numel(project.parameters.methods),1);
for k=1:numel(project.parameters.methods)
    sim=prototype.run_control_case(project,s,project.parameters.methods(k));rows{k}=sim.summary;
end
M=vertcat(rows{:});pass=all(M.completed)&all(M.estimator_finite)&all(M.illegal_duration_count==0);
writetable(M,fullfile(project.dirs.summary,'smoke_metrics.csv'));result=struct('pass',pass,'metrics',M);
end
