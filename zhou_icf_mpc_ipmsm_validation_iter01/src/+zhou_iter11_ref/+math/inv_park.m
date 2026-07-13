function ab = inv_park(dq, theta)
%INV_PARK Paper equation (6): dq to stationary alpha-beta coordinates.

R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
ab = R * dq(:);
end

