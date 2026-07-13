function [row,trace,simulation,success] = execute_ipmsm_case_safe( ...
        project,scenario,experiment_name,save_trace,template)
%EXECUTE_IPMSM_CASE_SAFE Record a failed condition without changing the core.

if nargin<5,template=table();end
try
    [row,trace,simulation]=zhou_validation.execute_ipmsm_case( ...
        project,scenario,experiment_name,save_trace);
    row.error_identifier="";row.error_message="";success=true;
catch exception
    if isempty(template),rethrow(exception);end
    row=template(1,:);trace=table();simulation=[];success=false;
    numeric=varfun(@isnumeric,row,'OutputFormat','uniform');
    names=row.Properties.VariableNames;
    for k=find(numeric),row.(names{k})(:)=NaN;end
    row.run_id=string(project.run_id);row.timestamp=string(project.timestamp);
    row.experiment=string(experiment_name);row.scenario=string(scenario.name);
    row.motor_model=string(field_or(scenario,'motor_model',"P1"));
    [Ld,Lq]=plant_inductances(project,scenario);
    row.Ld=Ld;row.Lq=Lq;
    row.Rs=project.motor.Rs_Ohm*field_or(scenario,'plant_Rs_scale',1);
    row.psi_f=project.motor.psi_f_Wb*field_or(scenario,'plant_psi_f_scale',1);
    row.speed_rpm=scenario.speed_rpm;row.iq_reference=scenario.iq_ref_A;
    row.id_reference=scenario.id_ref_A;row.alpha_mode=string(scenario.alpha_mode);
    row.F_estimator=string(scenario.F_estimator);row.sampling_period=project.base.Ts_s;
    row.integration_step=field_or(scenario,'integration_step_s',Inf);
    row.steady_state_start=scenario.steady_window_start_s;
    row.steady_state_end=scenario.simulation_time_s;row.pass_fail="FAIL";
    row.illegal_commands=1;row.negative_durations=NaN;
    row.error_identifier=string(exception.identifier);row.error_message=string(exception.message);
    log_error(project,scenario,experiment_name,exception);
end
end

function [Ld,Lq]=plant_inductances(project,s)
if string(field_or(s,'motor_model',"P1"))=="P0"
    Ld=project.motor.Ls_H;Lq=project.motor.Ls_H;
else
    Ld=project.motor.Ld_H*field_or(s,'plant_Ld_scale',1);
    Lq=project.motor.Lq_H*field_or(s,'plant_Lq_scale',1);
end
end
function log_error(project,s,experiment,e)
name=regexprep(string(s.name),'[^A-Za-z0-9._-]','_');
path_value=fullfile(project.root,'diagnostics','runtime_errors', ...
    project.run_id+"_"+experiment+"_"+name+".txt");
fid=fopen(path_value,'w','n','UTF-8');if fid<0,return;end
cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'scenario: %s\nidentifier: %s\nmessage: %s\n\n%s', ...
    s.name,e.identifier,e.message,getReport(e,'extended'));
end
function value=field_or(s,name,default_value)
if isfield(s,name),value=s.(name);else,value=default_value;end
end
