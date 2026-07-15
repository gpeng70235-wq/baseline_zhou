function command = synthesize_feasible_three_vector_command(point_ab,Ts,vectors,assumptions)
%SYNTHESIZE_FEASIBLE_THREE_VECTOR_COMMAND Re-synthesize S2/S3 dwell times.
% No clipping or renormalization of barycentric duties is performed.

arguments
    point_ab (1,2) double {mustBeFinite}
    Ts (1,1) double {mustBeFinite,mustBePositive}
    vectors struct
    assumptions struct
end
sector_tolerance=field_or(assumptions,'sector_angle_tolerance_rad',1e-12);
duty_tolerance=field_or(assumptions,'duty_tolerance',1e-12);
voltage_tolerance=field_or(assumptions,'voltage_tolerance_V',1e-10);

if norm(point_ab)<=voltage_tolerance
    command=zhou_ipmsm.modulation.case1_command(Ts,vectors);
    command.assumption="feasibility_layer_degenerate_zero_command";
    return
end
[sector,boundary]=zhou_ipmsm.geometry.sector_of_point(point_ab,sector_tolerance);
low_by_sector=[1,3,3,5,5,1];high_by_sector=[2,2,4,4,6,6];
low_id=low_by_sector(sector);high_id=high_by_sector(sector);
A=[vectors.ab_V(low_id+1,:).',vectors.ab_V(high_id+1,:).'];
d=A\point_ab(:);d0=1-sum(d);
ids=[0,low_id,high_id,low_id,0];
sequence_durations=[d0/2,d(1)/2,d(2),d(1)/2,d0/2]*Ts;
states=vectors.states(ids+1,:);
equivalent=d(1)*vectors.ab_V(low_id+1,:)+d(2)*vectors.ab_V(high_id+1,:);
[inside_hexagon,hex_audit]=zhou_feasibility.point_in_hexagon(point_ab,vectors,voltage_tolerance);
legal=inside_hexagon && all([d0;d]>=-duty_tolerance) && ...
    all([d0;d]<=1+duty_tolerance) && ...
    all(sequence_durations>=-100*eps(Ts)) && ...
    abs(sum(sequence_durations)-Ts)<=100*eps(Ts);

command=struct();
command.case_id=3;
command.reference_ab_V=point_ab;
command.selected_vector=NaN;
command.active_vector_ids=[low_id,high_id];
command.duties=[d0,d(1),d(2)];
command.durations_s=command.duties*Ts;
command.sequence_vector_ids=ids;
command.sequence_states=states;
command.sequence_durations_s=sequence_durations;
command.switching_actions=4;
command.positive_duration_switching_actions= ...
    zhou_ipmsm.inverter.count_sequence_transitions(states(sequence_durations>0,:));
command.equivalent_ab_V=equivalent;
command.legal=legal;
command.sector=sector;
command.sector_boundary=boundary;
command.assumption="feasibility_layer_barycentric_three_vector_symmetric_DPWM";
command.feasibility_audit=struct('inside_hexagon',inside_hexagon, ...
    'minimum_hexagon_slack_V',hex_audit.minimum_slack_V, ...
    'duty_sum',sum(command.duties), ...
    'minimum_duty',min(command.duties), ...
    'duration_sum_s',sum(sequence_durations), ...
    'reconstruction_residual_V',norm(equivalent-point_ab));
end

function value=field_or(s,name,default_value)
if isfield(s,name),value=s.(name);else,value=default_value;end
end
