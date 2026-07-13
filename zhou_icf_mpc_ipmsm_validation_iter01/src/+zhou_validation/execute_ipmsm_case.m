function [row,trace,simulation] = execute_ipmsm_case(project,scenario,experiment_name,save_trace)
%EXECUTE_IPMSM_CASE Run one isolated IPMSM condition and optionally persist trace.

if nargin<4, save_trace=false; end
run_project=project;
run_project.paper=project.motor;
run_project.assumptions.dc_bus_V=project.base.ipmsm_dc_bus_V;
run_project.assumptions.inverter_disturbance_model="none";
run_project.assumptions.current_reference_ramp_s=scenario.reference_ramp_s;
run_project.assumptions.waveform_sample_period_s=min(2e-6, ...
    field_or(scenario,'integration_step_s',2e-6));
simulation=zhou_ipmsm.sim.run_closed_loop("ICF_MPC",scenario,run_project);
[row,trace]=zhou_validation.summarize_ipmsm_simulation(simulation,run_project,experiment_name);
if save_trace
    directory=fullfile(project.root,'results',experiment_name,project.run_id);
    if ~isfolder(directory), mkdir(directory); end
    scales=[field_or(scenario,'plant_Ld_scale',1), ...
        field_or(scenario,'plant_Lq_scale',1),field_or(scenario,'plant_Rs_scale',1), ...
        field_or(scenario,'plant_psi_f_scale',1)];
    scale_token=strjoin(cellstr(compose('%.6g',scales)),'_');
    filename=sprintf('%s__%s__%s__%s__id_%s__pole_%s__scales_%s.csv', ...
        char(sanitize(string(scenario.name))), ...
        char(sanitize(string(field_or(scenario,'motor_model',"P1")))), ...
        char(sanitize(string(field_or(scenario,'alpha_mode',"axis_specific")))), ...
        char(sanitize(string(field_or(scenario,'F_estimator',"algebraic_iter11")))), ...
        char(sanitize(scalar_token(field_or(scenario,'id_ref_A',0)))), ...
        char(sanitize(scalar_token(field_or(scenario,'eso_pole',NaN)))),scale_token);
    writetable(trace,fullfile(directory,filename));
end
end

function value=field_or(s,name,default_value)
if isfield(s,name), value=s.(name); else, value=default_value; end
end
function value=sanitize(value)
value=regexprep(value,'[^A-Za-z0-9._-]','_');
end
function value=scalar_token(input)
if isnumeric(input) && isscalar(input)
    if isnan(input),value="nan";else,value=string(sprintf('%.6g',input));end
else
    value=string(input);
end
end
