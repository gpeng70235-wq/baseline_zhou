function result=calibration(project)
%CALIBRATION Preregistered three-case, three-candidate local comparison.
ids=project.parameters.calibration_set;
candidates=[struct('id',"design_default",'override',struct()); ...
    struct('id',"conservative",'override',struct('gamma_alpha',[.015;.015], ...
    'beta_F',[.1875;.1875],'rho_F',[.25;.25])); ...
    struct('id',"aggressive",'override',struct('gamma_alpha',[.025;.025], ...
    'beta_F',[.3125;.3125],'rho_F',[.75;.75]))];
rows=cell(numel(candidates),1);
for k=1:numel(candidates)
    tag="calibration_"+candidates(k).id;
    q=prototype.run_suite(project,ids,"P",1,tag,candidates(k).override);
    m=q.method_metrics;
    stable=all(q.case_metrics.completed|q.case_metrics.illegal)&all(q.case_metrics.estimator_finite)& ...
        all(q.case_metrics.illegal_duration_count==0);
    rows{k}=table(candidates(k).id,m.false_safe_rate,m.false_alarm_rate,m.vector_rms_A, ...
        m.phase_thd,m.torque_ripple_Nm,stable,'VariableNames',{'candidate','false_safe_rate', ...
        'false_alarm_rate','vector_rms_A','phase_thd','torque_ripple_Nm','numerically_stable'});
end
C=vertcat(rows{:});admissible=C.numerically_stable&C.false_alarm_rate<=.05;
assert(any(admissible),'Prototype:NoCalibrationCandidate');
score=C.false_safe_rate+1e-3*C.false_alarm_rate+1e-6*C.vector_rms_A;score(~admissible)=Inf;
[~,chosen_index]=min(score);C.selected=false(height(C),1);C.selected(chosen_index)=true;
writetable(C,fullfile(project.dirs.summary,'parameter_calibration.csv'));
chosen=C.candidate(chosen_index);pass=chosen=="design_default";
parameter_file=fullfile(project.root,'config','FROZEN_PROTOTYPE_PARAMETERS.m');
hash=zhou_ipmsm.io.file_sha256(parameter_file);
writelines(["file,sha256";string(parameter_file)+","+hash],fullfile(project.dirs.audit,'PARAMETER_FREEZE_SHA256.txt'));
lines=["# Parameter Calibration Report";"";"Calibration used only C01, P08 and D03."; ...
    "The three candidates were the frozen design default and two local ±25% bandwidth variants; no 24-case validation data were used."; ...
    "";"Selected candidate: **"+chosen+"**.";""; ...
    "The immutable parameter file SHA256 is `"+hash+"`."];
writelines(lines,fullfile(project.dirs.docs,'PARAMETER_CALIBRATION_REPORT.md'));
result=struct('pass',pass,'selected',chosen,'candidates',C,'parameter_sha256',hash);
end
