function result = voltage_feasibility(reference_ab, vectors, command, tolerance)
%VOLTAGE_FEASIBILITY Independent two-way audit of inverter feasibility.
%
% result = zhou_voltage_diag.voltage_feasibility(reference_ab, vectors, ...
%     command, tolerance)
%
% The regular-hexagon test is evaluated directly from its six half spaces.
% It intentionally does not call CASE3_COMMAND, SECTOR_OF_POINT, or reuse a
% command's LEGAL flag.  A second, sector-barycentric test reconstructs the
% point using the two adjacent active vectors.  If COMMAND contains three
% duties, those original values are audited separately as well.

arguments
    reference_ab (1,2) double {mustBeFinite}
    vectors struct
    command struct = struct()
    tolerance (1,1) double {mustBeFinite,mustBeNonnegative} = 1e-12
end

[active_magnitude, dc_bus_V, voltage_vector_scale] = vector_parameters(vectors);
active_angles = (0:5).' * pi/3;
active_vectors = active_magnitude * [cos(active_angles), sin(active_angles)];

% Independent regular-hexagon half-space representation.  The outward
% normals bisect adjacent active vectors and the apothem is R*cos(pi/6).
normal_angles = pi/6 + (0:5).' * pi/3;
halfspace_normals = [cos(normal_angles), sin(normal_angles)];
apothem = active_magnitude * cos(pi/6);
projections = halfspace_normals * reference_ab(:);
voltage_tolerance = tolerance * max(1, active_magnitude);
halfspace_slacks = apothem - projections;
inside_halfspace = all(halfspace_slacks >= -voltage_tolerance);

magnitude = norm(reference_ab);
if magnitude <= voltage_tolerance
    angle_rad = NaN;
    sector = 0;
    sector_boundary = true;
    radial_limit = active_magnitude;
    utilization = 0;
    radial_margin = active_magnitude;
    limiting_halfspace = NaN;
    radial_boundary_ab = [NaN, NaN];
    active_vector_ids = [0, 0];
    V1_ab = [0, 0];
    V2_ab = [0, 0];
    barycentric_active = [0, 0];
else
    angle_rad = mod(atan2(reference_ab(2), reference_ab(1)), 2*pi);
    scaled_angle = angle_rad / (pi/3);
    nearest_boundary = round(scaled_angle);
    sector_boundary = abs(scaled_angle - nearest_boundary) <= tolerance;
    if sector_boundary
        % Same explicit half-open convention documented by the controller:
        % a vector-angle boundary starts the following sector.
        sector = mod(nearest_boundary, 6) + 1;
    else
        sector = floor(scaled_angle) + 1;
    end

    low_by_sector = [1, 3, 3, 5, 5, 1];
    high_by_sector = [2, 2, 4, 4, 6, 6];
    active_vector_ids = [low_by_sector(sector), high_by_sector(sector)];
    V1_ab = active_vectors(active_vector_ids(1), :);
    V2_ab = active_vectors(active_vector_ids(2), :);
    barycentric_active = [V1_ab(:), V2_ab(:)] \ reference_ab(:);
    barycentric_active = barycentric_active.';

    direction = reference_ab(:) / magnitude;
    directional_cosines = halfspace_normals * direction;
    candidates = inf(6,1);
    positive = directional_cosines > 0;
    candidates(positive) = apothem ./ directional_cosines(positive);
    [radial_limit, limiting_halfspace] = min(candidates);
    utilization = magnitude / radial_limit;
    radial_margin = radial_limit - magnitude;
    radial_boundary_ab = (radial_limit * direction).';
end

barycentric_duties = [1-sum(barycentric_active), barycentric_active];
rho_recomputed = sum(barycentric_duties(2:3));
identity_recomputed = barycentric_duties(1) - (1-rho_recomputed);
barycentric_reconstruction = barycentric_duties(2)*V1_ab + ...
    barycentric_duties(3)*V2_ab;
barycentric_residual = norm(reference_ab - barycentric_reconstruction);
inside_barycentric = all(barycentric_duties >= -tolerance) && ...
    all(barycentric_duties <= 1+tolerance);

command_duties = [NaN, NaN, NaN];
has_command_duties = isfield(command, 'duties') && ...
    isnumeric(command.duties) && numel(command.duties) == 3 && ...
    all(isfinite(command.duties(:)));
if has_command_duties
    command_duties = reshape(double(command.duties), 1, 3);
end

if has_command_duties
    reported_duties = command_duties;
    duty_source = "command";
else
    reported_duties = barycentric_duties;
    duty_source = "recomputed";
end
rho = reported_duties(2) + reported_duties(3);
identity_residual = reported_duties(1) - (1-rho);
inside_command_duties = all(reported_duties >= -tolerance) && ...
    all(reported_duties <= 1+tolerance);

false_positive = inside_barycentric && ~inside_halfspace;
false_negative = ~inside_barycentric && inside_halfspace;
command_false_positive = inside_command_duties && ~inside_halfspace;
command_false_negative = ~inside_command_duties && inside_halfspace;

result = struct();
result.reference_ab_V = reference_ab;
result.dc_bus_V = dc_bus_V;
result.voltage_vector_scale = voltage_vector_scale;
result.active_magnitude_V = active_magnitude;
result.hex_apothem_V = apothem;
result.magnitude_V = magnitude;
result.angle_rad = angle_rad;
result.sector = sector;
result.sector_boundary = sector_boundary;
result.active_vector_ids = active_vector_ids;
result.V1_ab = V1_ab;
result.V2_ab = V2_ab;
result.barycentric_duties = barycentric_duties;
result.barycentric_reconstruction_ab_V = barycentric_reconstruction;
result.barycentric_residual_V = barycentric_residual;
result.command_duties = command_duties;
result.reported_duties = reported_duties;
result.duty_source = duty_source;
result.d0 = reported_duties(1);
result.d1 = reported_duties(2);
result.d2 = reported_duties(3);
result.rho_recomputed = rho_recomputed;
result.d0_recomputed = barycentric_duties(1);
result.d0_from_rho_recomputed = 1-rho_recomputed;
result.identity_recomputed_residual = identity_recomputed;
result.rho = rho;
result.d0_from_rho = 1-rho;
result.identity_residual = identity_residual;
result.halfspace_normals = halfspace_normals;
result.halfspace_projections_V = projections;
result.halfspace_slacks_V = halfspace_slacks;
result.limiting_halfspace = limiting_halfspace;
result.hex_radial_limit_V = radial_limit;
result.radial_boundary_ab_V = radial_boundary_ab;
result.utilization_ratio = utilization;
result.rho_utilization_residual = rho_recomputed-utilization;
result.command_rho_utilization_residual = rho-utilization;
result.hex_margin_V = radial_margin;
result.minimum_halfspace_margin_V = min(halfspace_slacks);
result.inside_halfspace = inside_halfspace;
result.inside_barycentric = inside_barycentric;
result.inside_command_duties = inside_command_duties;
result.inside_hexagon = inside_halfspace;
result.criteria_agree = inside_halfspace == inside_barycentric;
result.false_positive = false_positive;
result.false_negative = false_negative;
result.command_false_positive = command_false_positive;
result.command_false_negative = command_false_negative;
result.tolerance = tolerance;
result.voltage_tolerance_V = voltage_tolerance;
end

function [magnitude, dc_bus_V, scale] = vector_parameters(vectors)
required = {'ab_V'};
for k = 1:numel(required)
    assert(isfield(vectors, required{k}), ...
        'ZhouVoltageDiag:MissingVectorField', ...
        'vectors.%s is required.', required{k});
end
assert(size(vectors.ab_V,1) >= 7 && size(vectors.ab_V,2) == 2, ...
    'ZhouVoltageDiag:InvalidVectors', ...
    'vectors.ab_V must contain V0 through V6 as a 7-by-2 array.');

derived = vecnorm(double(vectors.ab_V(2:7,:)), 2, 2);
assert(all(isfinite(derived)) && all(derived > 0), ...
    'ZhouVoltageDiag:InvalidVectors', ...
    'All six active vectors must be finite and nonzero.');
magnitude = mean(derived);
assert(max(abs(derived-magnitude)) <= 1e-10*max(1,magnitude), ...
    'ZhouVoltageDiag:NonRegularHexagon', ...
    'The six active vectors do not have one common magnitude.');

if isfield(vectors, 'active_magnitude_V')
    asserted_magnitude = double(vectors.active_magnitude_V);
    assert(isscalar(asserted_magnitude) && isfinite(asserted_magnitude) && ...
        abs(asserted_magnitude-magnitude) <= 1e-10*max(1,magnitude), ...
        'ZhouVoltageDiag:VectorMagnitudeMismatch', ...
        'vectors.active_magnitude_V disagrees with vectors.ab_V.');
end
if isfield(vectors, 'dc_bus_V')
    dc_bus_V = double(vectors.dc_bus_V);
else
    dc_bus_V = NaN;
end
if isfield(vectors, 'scale')
    scale = double(vectors.scale);
else
    scale = NaN;
end
end
