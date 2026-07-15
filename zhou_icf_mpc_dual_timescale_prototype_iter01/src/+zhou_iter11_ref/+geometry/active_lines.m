function lines = active_lines()
%ACTIVE_LINES Paper equation (10), represented as a*x+b*y=0.

lines.names = ["L1: y=0"; "L2: y-sqrt(3)x=0"; ...
               "L3: y+sqrt(3)x=0"];
lines.coefficients = [0, 1; -sqrt(3), 1; sqrt(3), 1];
lines.directions = [1, 0; 0.5, sqrt(3)/2; -0.5, sqrt(3)/2];
end

