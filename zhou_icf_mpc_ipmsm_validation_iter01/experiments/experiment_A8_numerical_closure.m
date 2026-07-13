function closure = experiment_A8_numerical_closure(project)
%EXPERIMENT_A8_NUMERICAL_CLOSURE RK4, indexing, voltage, and metric identities.

s=project.experiments(4); s.motor_model="P1"; s.alpha_mode="axis_specific";
s.F_estimator="algebraic_iter11"; s.simulation_time_s=.06;
s.steady_window_start_s=.03;
steps=[2 1 .5 .25]*1e-6;
rows=cell(numel(steps),1); finals=zeros(numel(steps),2); traces=cell(numel(steps),1);
for k=1:numel(steps)
    s.integration_step_s=steps(k);
    [row,tr,sim]=zhou_validation.execute_ipmsm_case(project,s,"numerical_closure",false);
    rows{k}=row; traces{k}=tr; finals(k,:)=sim.final_state(1:2).';
end
closure=vertcat(rows{:});
endpoint_error_A=vecnorm(finals-finals(end,:),2,2);
closure.endpoint_error_to_finest_A=endpoint_error_A;
convergence_ok=all(endpoint_error_A<=1e-9) || ...
    all(diff(endpoint_error_A(1:end-1))<=1e-12);
closure.convergence_monotone=repmat(convergence_ok,numel(steps),1);

tr=traces{1}; sim_project=project;
sim_project.assumptions.dc_bus_V=project.base.ipmsm_dc_bus_V;
[u3_error,u4_error,exact_error]=voltage_reconstruction_errors(tr,sim_project,s);
alignment_mismatch=nnz(tr.selected_vectors(1:end-1)~=tr.applied_vectors(2:end));
case_alignment_mismatch=nnz(tr.case_selected(1:end-1)~=tr.case_applied(2:end));
recomputed=max(0,abs(tr.id_ref_A-tr.plant_id_k2_A)-sqrt(s.Jd_limit_A2));
constraint_identity_error=max(abs(recomputed-tr.actual_exceedance_d_A),[],'omitnan');
illegal_semantic_ok=islogical(tr.illegal_command) && all(ismember(double(tr.illegal_command),[0 1]));
window_consistent=numel(unique(closure.steady_state_start))==1 && ...
    numel(unique(closure.steady_state_end))==1;
gate=max(exact_error)<project.thresholds.U3_U4_max_error_V && ...
    mean(exact_error)<project.thresholds.U3_U4_mean_error_V && ...
    convergence_ok && alignment_mismatch==0 && ...
    case_alignment_mismatch==0 && constraint_identity_error<1e-12 && ...
    illegal_semantic_ok && window_consistent;
row_count=height(closure);
closure.U3_internal_max_error_V=repmat(max(u3_error),row_count,1);
closure.U4_internal_max_error_V=repmat(max(u4_error),row_count,1);
closure.midpoint_vs_exact_max_error_V=repmat(max(exact_error),row_count,1);
closure.midpoint_vs_exact_mean_error_V=repmat(mean(exact_error),row_count,1);
closure.queue_alignment_mismatches=repmat(alignment_mismatch,row_count,1);
closure.case_alignment_mismatches=repmat(case_alignment_mismatch,row_count,1);
closure.constraint_identity_error_A=repmat(constraint_identity_error,row_count,1);
closure.illegal_semantic_ok=repmat(illegal_semantic_ok,row_count,1);
closure.thd_window_consistent=repmat(window_consistent,row_count,1);
closure.numerical_gate=repmat(string(pass_text(gate)),height(closure),1);
writetable(closure,fullfile(project.root,'results','numerical_closure', ...
    project.run_id,'metrics.csv'));
writetable(closure,fullfile(project.root,'results','summary','numerical_closure.csv'));
write_audit(project,closure,gate);
end

function [e3,e4,e_exact]=voltage_reconstruction_errors(T,project,s)
vectors=zhou_ipmsm.inverter.voltage_vectors(project.assumptions.dc_bus_V, ...
    project.assumptions.voltage_vector_scale);
n=height(T); e3=zeros(n,1);e4=zeros(n,1);e_exact=zeros(n,1);
omega=s.speed_rpm*2*pi/60*project.motor.pole_pairs; Ts=project.base.Ts_s;
for k=1:n
    applied=command_from_strings(T.applied_vectors(k),T.applied_durations_s(k));
    selected=command_from_strings(T.selected_vectors(k),T.selected_durations_s(k));
    u3=zhou_ipmsm.controller.sequence_equivalent_dq_voltage(applied,vectors, ...
        T.theta_rad(k),omega,0,Ts,"execution_segment_midpoint");
    u4=zhou_ipmsm.controller.sequence_equivalent_dq_voltage(selected,vectors, ...
        T.theta_rad(k),omega,1,Ts,"execution_segment_midpoint");
    e3(k)=norm(u3-[T.U3d_V(k);T.U3q_V(k)]);
    e4(k)=norm(u4-[T.U4d_V(k);T.U4q_V(k)]);
    exact=exact_average(selected,vectors,T.theta_rad(k),omega,Ts,Ts);
    e_exact(k)=norm(exact-u4);
end
end
function c=command_from_strings(ids,durations)
c.sequence_vector_ids=str2double(split(string(ids),';')).';
c.sequence_durations_s=str2double(split(string(durations),';')).';
end
function u=exact_average(c,vectors,theta,omega,delay,Ts)
u=[0;0]; elapsed=0;
for j=1:numel(c.sequence_vector_ids)
    dt=c.sequence_durations_s(j); ab=vectors.ab_V(c.sequence_vector_ids(j)+1,:);
    t0=delay+elapsed; t1=t0+dt;
    if abs(omega)<eps
        integral=dt*zhou_ipmsm.math.park(ab,theta);
    else
        C=(sin(theta+omega*t1)-sin(theta+omega*t0))/omega;
        S=(-cos(theta+omega*t1)+cos(theta+omega*t0))/omega;
        integral=[ab(1)*C+ab(2)*S;-ab(1)*S+ab(2)*C];
    end
    u=u+integral/Ts; elapsed=elapsed+dt;
end
end
function write_audit(project,T,gate)
fid=fopen(fullfile(project.root,'diagnostics','numerical_closure_audit.md'), ...
    'w','n','UTF-8'); assert(fid>=0); cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'# Numerical closure audit\n\n- run_id: `%s`\n- gate: **%s**\n\n', ...
    project.run_id,pass_text(gate));
fprintf(fid,['`U3_internal` and `U4_internal` compare logged values with an independent ' ...
    'reconstruction of the same segment-midpoint convention. `midpoint_vs_exact` is ' ...
    'the gated selected-sequence midpoint U3 versus exact rotating-frame U4 error; ' ...
    'the exact value is offline and is not substituted into the controller.\n\n']);
fprintf(fid,'| RK4 max step (s) | endpoint error to finest (A) |\n|---:|---:|\n');
for k=1:height(T),fprintf(fid,'| %.9g | %.9g |\n',T.integration_step(k),T.endpoint_error_to_finest_A(k));end
end
function value=pass_text(condition)
if condition, value='PASS'; else, value='FAIL'; end
end
