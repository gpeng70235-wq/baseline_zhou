function vectors = voltage_vectors(dc_bus_V, scale)
%VOLTAGE_VECTORS Zhou Fig. 2 active-vector numbering and switch states.
% V0 is 000. V1...V6 are 100,110,010,011,001,101.

arguments
    dc_bus_V (1,1) double {mustBePositive}
    scale (1,1) double {mustBePositive} = 2/3
end

vectors.ids = (0:6).';
vectors.names = ["V0"; "V1"; "V2"; "V3"; "V4"; "V5"; "V6"];
vectors.states = [0 0 0; 1 0 0; 1 1 0; 0 1 0; ...
                  0 1 1; 0 0 1; 1 0 1];
vectors.angles_rad = [NaN; (0:5).' * pi/3];
active_magnitude = scale * dc_bus_V;
vectors.active_magnitude_V = active_magnitude;
vectors.ab_V = zeros(7, 2);
vectors.ab_V(2:end, :) = active_magnitude * ...
    [cos(vectors.angles_rad(2:end)), sin(vectors.angles_rad(2:end))];
vectors.dc_bus_V = dc_bus_V;
vectors.scale = scale;
end

