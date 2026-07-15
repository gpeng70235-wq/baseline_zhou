function q = s2_input_quality_gate(logrow,p)
%S2_INPUT_QUALITY_GATE Validate the just-completed post-S2 execution log.
q=struct('pass',false,'reason',"startup_no_completed_command", ...
    'step_scale',0,'reconstruction_residual_V',NaN,'utilization',NaN, ...
    'zero_command',false,'u_reconstructed',[NaN;NaN]);
if isempty(logrow) || ~isfield(logrow,'command'), return; end
c=logrow.command; d=c.sequence_durations_s(:); ids=c.sequence_vector_ids(:);
if isempty(d)||numel(d)~=numel(ids)||any(~isfinite(d))||any(d<-p.duration_tolerance_s)
    q.reason="invalid_segment_duration"; return
end
if abs(sum(d)-p.Ts_s)>p.duration_tolerance_s
    q.reason="duration_sum_not_Ts"; return
end
if any(ids~=round(ids))||any(ids<0)||any(ids>6)
    q.reason="invalid_vector_id"; return
end
if ~isfinite(logrow.Vdc)||logrow.Vdc<=0||~isfinite(logrow.theta_start)||~isfinite(logrow.omega_e)
    q.reason="invalid_voltage_or_angle_metadata"; return
end
if ~isfield(c,'legal')||~logical(c.legal)
    q.reason="unknown_or_illegal_clipping"; return
end
try
    u=zhou_ipmsm.controller.sequence_equivalent_dq_voltage(c,logrow.vectors, ...
        logrow.theta_start,logrow.omega_e,0,p.Ts_s,"execution_segment_midpoint");
catch
    q.reason="reconstruction_failure"; return
end
q.u_reconstructed=u;
q.reconstruction_residual_V=norm(u(:)-logrow.u_app(:));
if ~all(isfinite(u))||q.reconstruction_residual_V>1e-8
    q.reason="reconstruction_mismatch"; return
end
vf=zhou_feasibility.voltage_feasibility(c.reference_ab_V,logrow.vectors,c,1e-12);
q.utilization=vf.utilization_ratio;
q.zero_command=all(ids==0)||norm(u)<1e-12;
q.step_scale=1;
if q.utilization>=p.high_utilization_ratio
    q.step_scale=p.high_utilization_step_scale;
end
q.pass=true; q.reason="trusted_post_s2_execution";
end
