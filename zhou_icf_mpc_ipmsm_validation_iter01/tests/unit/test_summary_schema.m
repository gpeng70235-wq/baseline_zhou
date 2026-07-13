function tests = test_summary_schema
tests = functiontests(localfunctions);
end

function testEveryRequiredMetadataFieldIsMaterialized(testCase)
[project,scenario]=validation_test_fixture("P1");
scenario.experiment="unit_schema";
scenario.alpha_mode="axis_specific";
scenario.speed_rpm=500;
scenario.simulation_time_s=25e-3;
scenario.steady_window_start_s=10e-3;
sim=zhou_ipmsm.sim.run_closed_loop("ICF_MPC",scenario,project);
summary=zhou_validation.summarize_ipmsm_simulation(sim,project,scenario.experiment);
required={'run_id','timestamp','experiment','scenario','motor_model', ...
    'Ld','Lq','Rs','psi_f','speed_rpm','iq_reference','id_reference', ...
    'alpha_mode','F_estimator','sampling_period','integration_step', ...
    'steady_state_start','steady_state_end','pass_fail'};
if istable(summary)
    verifyEqual(testCase,height(summary),1);
    names=summary.Properties.VariableNames;
else
    verifyTrue(testCase,isstruct(summary) && isscalar(summary));
    names=fieldnames(summary).';
end
verifyTrue(testCase,all(ismember(required,names)), ...
    "Missing summary fields: "+strjoin(string(setdiff(required,names)),', '));
verifyEqual(testCase,double(value_of(summary,'sampling_period')),project.base.Ts_s,'AbsTol',0);
verifyEqual(testCase,string(value_of(summary,'scenario')),string(scenario.name));
verifyTrue(testCase,isfinite(double(value_of(summary,'Ld'))));
verifyTrue(testCase,isfinite(double(value_of(summary,'Lq'))));
verifyFalse(testCase,ismissing(string(value_of(summary,'pass_fail'))));
end

function value=value_of(summary,name)
if istable(summary), value=summary.(name)(1); else, value=summary.(name); end
end
