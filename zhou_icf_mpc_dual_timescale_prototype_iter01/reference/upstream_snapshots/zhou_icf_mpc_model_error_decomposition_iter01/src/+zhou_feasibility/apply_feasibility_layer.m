function [output,audit]=apply_feasibility_layer(control,input,cfg,strategy)
%APPLY_FEASIBILITY_LAYER Explicit post-Zhou voltage-feasibility policy.
% F, alpha, rectangle construction, Case 1/2, and one-cycle queue semantics
% remain untouched. Only an illegal original Case 3 command is replaced.

arguments
    control struct
    input struct
    cfg struct
    strategy (1,1) string {mustBeMember(strategy,["original_zhou", ...
        "radial_hex_projection","proposed_feasibility_aware"])}
end

output=control;original=control.command;rect=control.geometry.rect;
audit=empty_audit(strategy,original);
if strategy=="original_zhou"
    return
end
timer=tic;
audit.original_reference_ab_V=original.reference_ab_V;
audit.original_duties=three_duties(original);
if original.case_id~=3
    audit.degenerated_to_original=true;
    audit.layer_execution_time_s=toc(timer);
    return
end
audit.original_inside_hexagon=zhou_feasibility.point_in_hexagon( ...
    original.reference_ab_V,cfg.vectors,cfg.assumptions.voltage_tolerance_V);

if audit.original_inside_hexagon
    assert(original.legal,'ZhouFeasibility:IndependentFeasibilityDisagreement', ...
        'Independent hexagon test says feasible but original Case 3 is illegal.');
    audit.degenerated_to_original=true;
    audit.layer_execution_time_s=toc(timer);
    return
end

assert(~original.legal,'ZhouFeasibility:IndependentFeasibilityDisagreement', ...
    'Independent hexagon test says infeasible but original Case 3 is legal.');
assert(original.case_id==3,'ZhouFeasibility:UnexpectedIllegalCase', ...
    'The feasibility layer may replace only an illegal original Case 3.');
switch strategy
    case "radial_hex_projection"
        f=zhou_feasibility.voltage_feasibility(original.reference_ab_V, ...
            cfg.vectors,original,cfg.assumptions.duty_tolerance);
        target_ab=f.radial_boundary_ab_V;
        target_dq=zhou_ipmsm.math.park(target_ab,rect.theta);
        normalized=(target_dq-rect.center_dq)./rect.half_dq;
        audit.radial_point_inside_rectangle=all(abs(normalized)<=1+1e-10);
        audit.intersection=zhou_feasibility.rectangle_hexagon_intersection( ...
            rect,cfg.vectors,cfg.assumptions.voltage_tolerance_V);
        audit.mode="S1_radial";
    case "proposed_feasibility_aware"
        intersection=zhou_feasibility.rectangle_hexagon_intersection( ...
            rect,cfg.vectors,cfg.assumptions.voltage_tolerance_V);
        audit.intersection=intersection;
        if intersection.nonempty
            choice=zhou_feasibility.nearest_point_in_rectangle_hexagon_intersection( ...
                rect,cfg.vectors,cfg.assumptions.voltage_tolerance_V);
            target_ab=choice.point_ab;
            target_dq=choice.point_dq;
            audit.mode="S2_intersection";
            audit.normalized_objective=choice.normalized_distance_squared;
        else
            choice=zhou_feasibility.minimum_normalized_constraint_violation_in_hexagon( ...
                rect,cfg.vectors,cfg.assumptions.voltage_tolerance_V);
            target_ab=choice.point_ab;
            target_dq=choice.point_dq;
            audit.mode="S3_fallback";
            audit.fallback_used=true;
            audit.normalized_objective=choice.objective;
            audit.fallback_Jd_ratio=choice.Jd_ratio;
            audit.fallback_Jq_ratio=choice.Jq_ratio;
            audit.fallback_d_violation=choice.d_violation;
            audit.fallback_q_violation=choice.q_violation;
        end
end

command=zhou_feasibility.synthesize_feasible_three_vector_command( ...
    target_ab,cfg.paper.Ts_s,cfg.vectors,cfg.assumptions);
command.reference_dq_at_selection=zhou_ipmsm.math.park(command.reference_ab_V,input.theta_e);
command.theta_at_selection=input.theta_e;
command.reference_dq_execution=zhou_ipmsm.controller.sequence_equivalent_dq_voltage( ...
    command,cfg.vectors,input.theta_e,input.omega_e,1,cfg.paper.Ts_s, ...
    cfg.assumptions.candidate_voltage_frame_mode);
predicted_k2=zhou_ipmsm.controller.predict_k2(control.predicted_k1_dq, ...
    control.Fhat_dq,command.reference_dq_execution, ...
    [cfg.paper.alpha_d;cfg.paper.alpha_q],cfg.paper.Ts_s);
[Jd,Jq]=zhou_ipmsm.controller.independent_costs(input.reference_dq,predicted_k2);
assert(command.legal && all(command.duties>=-cfg.assumptions.duty_tolerance), ...
    'ZhouFeasibility:LayerSynthIllegal','Feasibility layer produced an illegal command.');

output.original_command=original;
output.command=command;
output.predicted_k2_dq=predicted_k2;
output.Jd=Jd;output.Jq=Jq;
output.constraint_satisfied_d=Jd<=cfg.Jd_limit+cfg.assumptions.constraint_tolerance;
output.constraint_satisfied_q=Jq<=cfg.Jq_limit+cfg.assumptions.constraint_tolerance;
output.selected_voltage_dq_used=command.reference_dq_execution;
audit.modified=true;
audit.target_ab_V=target_ab;
audit.target_dq_V=target_dq;
audit.offset_ab_V=norm(target_ab-original.reference_ab_V);
audit.offset_normalized=sqrt(sum(((target_dq-rect.center_dq)./rect.half_dq).^2));
audit.selected_Jd=Jd;audit.selected_Jq=Jq;
audit.selected_d_satisfied=output.constraint_satisfied_d;
audit.selected_q_satisfied=output.constraint_satisfied_q;
audit.layer_execution_time_s=toc(timer);
end

function a=empty_audit(strategy,command)
a=struct('strategy',strategy,'mode',"unchanged",'modified',false, ...
    'degenerated_to_original',false,'fallback_used',false, ...
    'original_legal',logical(command.legal),'original_inside_hexagon',false, ...
    'original_reference_ab_V',[NaN NaN],'original_duties',[NaN NaN NaN], ...
    'target_ab_V',command.reference_ab_V,'target_dq_V',[NaN;NaN], ...
    'offset_ab_V',0,'offset_normalized',0,'normalized_objective',0, ...
    'radial_point_inside_rectangle',true,'fallback_Jd_ratio',0, ...
    'fallback_Jq_ratio',0,'fallback_d_violation',0,'fallback_q_violation',0, ...
    'selected_Jd',NaN,'selected_Jq',NaN,'selected_d_satisfied',true, ...
    'selected_q_satisfied',true,'layer_execution_time_s',0, ...
    'intersection',struct('nonempty',NaN,'area_V2',NaN));
end
function d=three_duties(command)
d=[NaN NaN NaN];if isfield(command,'duties'),v=command.duties(:).';d(1:min(3,numel(v)))=v(1:min(3,numel(v)));end
end
