function ok = validate_candidate_geometry(command, Ts, rect, tolerance)
%VALIDATE_CANDIDATE_GEOMETRY Validate sequence and optional rectangle membership.
if nargin < 4
    tolerance = 1e-10;
end
ok = isfield(command,'legal') && command.legal && ...
    zhou_ipmsm.modulation.validate_durations(command.sequence_durations_s,Ts,tolerance);
if nargin >= 3 && ~isempty(rect)
    point_dq = zhou_ipmsm.inverter.park(command.reference_ab_V,rect.theta);
    residual = abs(point_dq-rect.center_dq)-rect.half_dq;
    ok = ok && all(residual <= tolerance);
end
end
