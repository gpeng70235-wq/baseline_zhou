function [sector, boundary] = sector_of_point(point_ab, tolerance)
%SECTOR_OF_POINT Six 60-degree sectors used in Zhou Fig. 2 and Table I.

arguments
    point_ab (1,2) double {mustBeFinite}
    tolerance (1,1) double {mustBeNonnegative} = 1e-10
end

if norm(point_ab) <= tolerance
    sector = 0;
    boundary = true;
    return;
end
angle = mod(atan2(point_ab(2), point_ab(1)), 2*pi);
scaled = angle / (pi/3);
nearest = round(scaled);
boundary = abs(scaled - nearest) <= tolerance;
if boundary
    % Deterministic half-open convention: a vector-angle boundary belongs
    % to the sector that starts at that angle (A08).
    sector = mod(nearest, 6) + 1;
else
    sector = floor(scaled) + 1;
end
end
