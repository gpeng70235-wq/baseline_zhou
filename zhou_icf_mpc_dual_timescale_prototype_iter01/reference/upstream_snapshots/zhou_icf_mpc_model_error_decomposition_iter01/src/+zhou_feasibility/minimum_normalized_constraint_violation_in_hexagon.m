function result = minimum_normalized_constraint_violation_in_hexagon(rect,vectors,tolerance)
%MINIMUM_NORMALIZED_CONSTRAINT_VIOLATION_IN_HEXAGON Solve strategy S3.
% Minimizes Jd/Jd_limit + Jq/Jq_limit over the inverter hexagon H.

arguments
    rect struct
    vectors struct
    tolerance (1,1) double {mustBeFinite,mustBeNonnegative} = 1e-10
end
half=rect.half_dq(:).';center=rect.center_dq(:).';
assert(all(half>0),'ZhouFeasibility:ZeroConstraintWidth', ...
    'Both normalized constraint half widths must be positive.');
hex_ab=double(vectors.ab_V(2:7,:));
origin=mean(hex_ab,1);
[~,order]=sort(mod(atan2(hex_ab(:,2)-origin(2),hex_ab(:,1)-origin(1)),2*pi));
hex_ab=hex_ab(order,:);
c=cos(rect.theta);s=sin(rect.theta);
hex_dq=([c,s;-s,c]*hex_ab.').';
normalized_hex=(hex_dq-center)./half;
projection=zhou_feasibility.project_point_to_polygon([0,0],normalized_hex,tolerance);
qstar=projection.point;
point_dq_row=center+half.*qstar;
point_ab=([c,-s;s,c]*point_dq_row.').';
[inside_hexagon,hex_audit]=zhou_feasibility.point_in_hexagon(point_ab,vectors,10*tolerance);
Jd_ratio=qstar(1)^2;Jq_ratio=qstar(2)^2;
d_violation=max(0,Jd_ratio-1);q_violation=max(0,Jq_ratio-1);
amplitude_violation_d=max(0,abs(qstar(1))-1);
amplitude_violation_q=max(0,abs(qstar(2))-1);
if d_violation>tolerance && q_violation>tolerance
    violated_axis="dq";
elseif d_violation>tolerance
    violated_axis="d";
elseif q_violation>tolerance
    violated_axis="q";
else
    violated_axis="none";
end

result=struct();
result.point_ab=point_ab;
result.point_dq=point_dq_row.';
result.point_dq_row=point_dq_row;
result.objective=Jd_ratio+Jq_ratio;
result.Jd_ratio=Jd_ratio;
result.Jq_ratio=Jq_ratio;
result.violation_d=d_violation;
result.violation_q=q_violation;
result.d_violation=d_violation;
result.q_violation=q_violation;
result.amplitude_violation_d=amplitude_violation_d;
result.amplitude_violation_q=amplitude_violation_q;
result.normalized_constraint_violation=d_violation+q_violation;
result.violated_axis=violated_axis;
result.inside_hexagon=inside_hexagon;
result.normalized_point=qstar;
result.hexagon_ab=hex_ab;
result.hexagon_dq=hex_dq;
result.normalized_hexagon=normalized_hex;
result.projection_audit=projection;
result.crosscheck_candidate_points_normalized=projection.candidate_points;
result.crosscheck_candidate_objectives=projection.candidate_distance2;
result.hexagon_audit=hex_audit;
end
