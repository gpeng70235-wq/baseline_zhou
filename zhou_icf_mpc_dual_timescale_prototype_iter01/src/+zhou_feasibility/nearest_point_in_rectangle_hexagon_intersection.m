function result = nearest_point_in_rectangle_hexagon_intersection(rect,vectors,tolerance)
%NEAREST_POINT_IN_RECTANGLE_HEXAGON_INTERSECTION Solve strategy S2.
% The objective is ((ud-ucd)/hd)^2+((uq-ucq)/hq)^2.

arguments
    rect struct
    vectors struct
    tolerance (1,1) double {mustBeFinite,mustBeNonnegative} = 1e-10
end
intersection=zhou_feasibility.rectangle_hexagon_intersection(rect,vectors,tolerance);
assert(intersection.nonempty,'ZhouFeasibility:EmptyIntersection', ...
    'R intersection H is empty; use the minimum-violation fallback.');
half=rect.half_dq(:).';center=rect.center_dq(:).';
assert(all(half>0),'ZhouFeasibility:ZeroConstraintWidth', ...
    'Both normalized constraint half widths must be positive.');
normalized_polygon=(intersection.polygon_dq-center)./half;
projection=zhou_feasibility.project_point_to_polygon([0,0],normalized_polygon,tolerance);
qstar=projection.point;
point_dq_row=center+half.*qstar;
c=cos(rect.theta);s=sin(rect.theta);
point_ab=([c,-s;s,c]*point_dq_row.').';
[inside_hexagon,hex_audit]=zhou_feasibility.point_in_hexagon(point_ab,vectors,10*tolerance);
inside_rectangle=all(abs(qstar)<=1+10*tolerance);

result=struct();
result.point_ab=point_ab;
result.point_dq=point_dq_row.';
result.point_dq_row=point_dq_row;
result.intersection=intersection;
result.distance2_normalized=sum(qstar.^2);
result.normalized_distance_squared=result.distance2_normalized;
result.Jd_ratio=qstar(1)^2;
result.Jq_ratio=qstar(2)^2;
result.violation_d=max(0,result.Jd_ratio-1);
result.violation_q=max(0,result.Jq_ratio-1);
result.d_violation=result.violation_d;
result.q_violation=result.violation_q;
result.inside_rectangle=inside_rectangle;
result.inside_hexagon=inside_hexagon;
result.normalized_point=qstar;
result.projection_audit=projection;
result.hexagon_audit=hex_audit;
end
