function dq = park(ab, theta)
%PARK Inverse of paper equation (6): alpha-beta to dq coordinates.

Rinv = [cos(theta), sin(theta); -sin(theta), cos(theta)];
dq = Rinv * ab(:);
end

