function data=run_campaign(project)
%RUN_CAMPAIGN Gated set audit and experiments A0-A4.
root=project.root;strategies=["original_zhou","radial_hex_projection","proposed_feasibility_aware"];

fprintf('A0 strict P0 regression...\n');
[p0_summary,p0_pointwise,p0_gate]=zhou_feasibility.run_p0_strict_regression(project);
assert(p0_gate,'ZhouFeasibility:P0RegressionGate','Formal three-condition P0 regression failed.');

fprintf('A0 frozen P1 failure reproduction...\n');
s0=control_scenario(project);s0.name="A0_P1_500rpm_20A_48V_5ms";
original=execute(s0,"original_zhou");
expected_d=[-0.052118594368426807,0.31494607480209075,0.73717251956633612];
expected_u=[6.75562,-29.1572];
p1_gate=original.illegal_event.occurred && ...
    abs(original.illegal_event.selected_time_s-.0044)<=1e-12 && ...
    abs(original.illegal_event.applied_time_s-.0045)<=1e-12 && ...
    max(abs(original.illegal_event.duties-expected_d))<=5e-13 && ...
    max(abs(original.illegal_event.reference_ab_V-expected_u))<=1e-4;
assert(p1_gate,'ZhouFeasibility:P1RegressionGate','Frozen P1 failure did not reproduce.');
writetable(original.trace,fullfile(root,'results','A0_frozen_regression',project.run_id,'P1_failure_trace.csv'));
writetable(addvars(original.summary,p1_gate,'NewVariableNames','reproduction_pass'), ...
    fullfile(root,'results','A0_frozen_regression',project.run_id,'P1_failure_summary.csv'));

fprintf('Set feasibility audit before modified closed loop...\n');
[intersection_audit,intersection_summary]=zhou_feasibility.audit_original_illegal_cycles(project,original);
writetable(intersection_audit,fullfile(root,'results','intersection_audit',project.run_id,'illegal_cycle_intersection_audit.csv'));
writetable(intersection_summary,fullfile(root,'results','intersection_audit',project.run_id,'intersection_audit_summary.csv'));
assert(intersection_summary.S2_preservable_fraction>0, ...
    'ZhouFeasibility:S2ZeroApplicability','S2 preserves no original illegal cycle; stop calling it primary.');

fprintf('A1 original failure strategy comparison...\n');
a1_sims=cell(3,1);a1_sims{1}=original;
for i=2:3,a1_sims{i}=execute(s0,strategies(i));end
A1=vertcat_summary(a1_sims);A1=add_status(A1);
writetable(A1,fullfile(root,'BASELINE_COMPARISON.csv'));
writetable(A1,fullfile(root,'results','A1_original_failure',project.run_id,'strategy_summary.csv'));
for i=1:3,writetable(a1_sims{i}.trace,fullfile(root,'results','A1_original_failure',project.run_id,strategies(i)+"_trace.csv"));end
a1_gate=a1_sims{3}.completed && a1_sims{3}.summary.illegal_command_count==0 && ...
    a1_sims{3}.summary.negative_duration_count==0;
assert(a1_gate,'ZhouFeasibility:A1Gate','Proposed failed the original 48 V / 5 ms case.');

fprintf('A2 six-condition P0/P1 matrix...\n');
base_conditions=six_condition_matrix(project);a2_sims=cell(36,1);n=0;
for c=1:6
    for model=["P0","P1"]
        for strategy=strategies
            n=n+1;s=base_conditions(c);s.motor_model=model;
            s.name=sprintf('A2_%drpm_%gA_%s_%s',s.speed_rpm,s.iq_ref_A,model,strategy);
            a2_sims{n}=execute(s,strategy);
            if c==6 && model=="P1"
                writetable(a2_sims{n}.trace,fullfile(root,'results','A2_six_condition',project.run_id, ...
                    sprintf('500rpm_20A_P1_%s_trace.csv',strategy)));
            end
        end
    end
end
A2=add_status(vertcat_summary(a2_sims));writetable(A2,fullfile(root,'SIX_CONDITION_COMPARISON.csv'));
writetable(A2,fullfile(root,'results','A2_six_condition',project.run_id,'six_condition_summary.csv'));
proposed_A2=A2(A2.strategy=="proposed_feasibility_aware",:);
a2_gate=all(proposed_A2.completed_0p2s) && all(proposed_A2.illegal_command_count==0) && ...
    all(proposed_A2.negative_duration_count==0);
assert(a2_gate,'ZhouFeasibility:A2Gate','Proposed did not legally complete all 12 paired conditions.');

fprintf('A3 Vdc-ramp boundary revalidation...\n');
vdcs=[48,50,50.5,50.5625,52,56];ramps=[.005,.00703125,.010,.020];
a3_sims=cell(numel(vdcs)*numel(ramps)*3,1);n=0;
for v=vdcs
    for ramp=ramps
        for strategy=strategies
            n=n+1;s=s0;s.dc_bus_V=v;s.reference_ramp_s=ramp;
            s.name=sprintf('A3_%gV_%gms_%s',v,1e3*ramp,strategy);
            a3_sims{n}=execute(s,strategy);
        end
    end
end
A3=add_status(vertcat_summary(a3_sims));
writetable(A3,fullfile(root,'results','A3_boundary',project.run_id,'Vdc_ramp_boundary_comparison.csv'));
proposed_A3=A3(A3.strategy=="proposed_feasibility_aware",:);
original_A3=A3(A3.strategy=="original_zhou",:);
feasible_original=original_A3.completed_0p2s;
degeneration_ok=true;
for k=find(feasible_original).'
    match=proposed_A3.dc_bus_V==original_A3.dc_bus_V(k) & ...
        abs(proposed_A3.reference_ramp_s-original_A3.reference_ramp_s(k))<1e-14;
    degeneration_ok=degeneration_ok && all(proposed_A3.modified_command_fraction(match)==0);
end
a3_gate=all(proposed_A3.completed_0p2s) && all(proposed_A3.illegal_command_count==0) && degeneration_ok;
assert(a3_gate,'ZhouFeasibility:A3Gate','Boundary legality or strict degeneration failed.');

fprintf('A4 negative-id admission probe...\n');
ids=[0,-2,-4,-6];speeds=[100,300,500];a4_sims=cell(numel(ids)*numel(speeds)*2,1);n=0;
for speed=speeds
    for id=ids
        iq=sqrt(20^2-id^2);
        for strategy=["original_zhou","proposed_feasibility_aware"]
            n=n+1;s=s0;s.speed_rpm=speed;s.id_ref_A=id;s.iq_ref_A=iq;
            s.name=sprintf('A4_%drpm_id%g_iq%.6g_%s',speed,id,iq,strategy);
            a4_sims{n}=execute(s,strategy);
        end
    end
end
A4=add_status(vertcat_summary(a4_sims));writetable(A4,fullfile(root,'NEGATIVE_ID_ADMISSION.csv'));
writetable(A4,fullfile(root,'results','A4_negative_id',project.run_id,'negative_id_admission.csv'));

execution=build_execution_table([A1;A2;A3]);writetable(execution,fullfile(root,'EXECUTION_TIME_COMPARISON.csv'));
data=struct('project',project,'p0_summary',p0_summary,'p0_pointwise',p0_pointwise, ...
    'p0_gate',p0_gate,'p1_gate',p1_gate,'intersection_audit',intersection_audit, ...
    'intersection_summary',intersection_summary,'A1',A1,'A1_traces',{{a1_sims{:}}}, ...
    'A2',A2,'A3',A3,'A4',A4,'execution',execution,'A1_gate',a1_gate, ...
    'A2_gate',a2_gate,'A3_gate',a3_gate,'degeneration_ok',degeneration_ok);
save(fullfile(root,'results','summary',project.run_id,'campaign_data.mat'),'data','-v7.3');

    function sim=execute(s,strategy)
        fprintf('  %-42s %-28s\n',char(s.name),char(strategy));
        sim=zhou_feasibility.run_control_case(project,s,strategy);
    end
end

function T=vertcat_summary(sims)
rows=cellfun(@(x)x.summary,sims,'UniformOutput',false);T=vertcat(rows{:});
end
function T=add_status(T)
status=repmat("FAIL",height(T),1);status(T.completed_0p2s & T.illegal_command_count==0 & T.negative_duration_count==0)="PASS";
T=addvars(T,status,'After','strategy','NewVariableNames','run_status');
end
function E=build_execution_table(T)
E=T(:,{'run_id','scenario','speed_rpm','id_ref_A','iq_ref_A','motor_model', ...
    'dc_bus_V','voltage_vector_scale', ...
    'active_vector_magnitude_V','reference_ramp_s','sampling_period_s','Ld_H','Lq_H', ...
    'alpha_mode','F_estimator','strategy','run_status','execution_time_average_s', ...
    'execution_time_p95_s','execution_time_max_s','feasibility_layer_time_average_s'});
end
