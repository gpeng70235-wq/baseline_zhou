function selection = select_savv(line_hits, center_ab, vectors, tolerance)
%SELECT_SAVV Paper Table I with the two documented minimal corrections A15.

arguments
    line_hits (1,3) logical
    center_ab (2,1) double {mustBeFinite}
    vectors struct
    tolerance (1,1) double {mustBeNonnegative} = 1e-10
end

[sector, sector_boundary] = ...
    zhou_ipmsm.geometry.sector_of_point(center_ab(:).', tolerance);
code = sprintf('%d%d%d', line_hits(1), line_hits(2), line_hits(3));
correction_used = false;
fallback_used = false;
candidates = [];

switch code
    case '100'
        candidates = [1, 4];
        if ismember(sector, [1, 6])
            selected = 1;
            correction_used = sector == 6; % printed entry omits VI
        elseif ismember(sector, [3, 4])
            selected = 4;
            correction_used = sector == 4; % printed table assigns IV twice
        else
            selected = nearest_candidate(center_ab, candidates, vectors);
            fallback_used = true;
        end
    case '010'
        candidates = [2, 5];
        if ismember(sector, [1, 2])
            selected = 2;
        elseif ismember(sector, [4, 5])
            selected = 5;
        else
            selected = nearest_candidate(center_ab, candidates, vectors);
            fallback_used = true;
        end
    case '001'
        candidates = [3, 6];
        if ismember(sector, [2, 3])
            selected = 3;
        elseif ismember(sector, [5, 6])
            selected = 6;
        else
            selected = nearest_candidate(center_ab, candidates, vectors);
            fallback_used = true;
        end
    case '110'
        candidates = [1, 5];
        if ismember(sector, [1, 2, 6])
            selected = 1;
        else
            selected = 5;
        end
    case '011'
        candidates = [3, 5];
        if ismember(sector, [1, 2, 3])
            selected = 3;
        else
            selected = 5;
        end
    case '101'
        candidates = [3, 1];
        if ismember(sector, [2, 3, 4])
            selected = 3;
            correction_used = ismember(sector, [2, 3]); % printed entry omits II/III
        else
            selected = 1;
        end
    case '111'
        candidates = 1:6;
        selected = nearest_candidate(center_ab, candidates, vectors);
    otherwise
        error('ZhouIPMSM:InvalidTableIInput', ...
            'Table I requires at least one AVV line hit; got %s.', code);
end

selection = struct();
selection.vector_id = selected;
selection.vector_name = vectors.names(selected + 1);
selection.sector = sector;
selection.sector_boundary = sector_boundary;
selection.line_code = string(code);
selection.candidates = candidates;
selection.table_I_correction_used = correction_used;
selection.fallback_used = fallback_used;
selection.mode = "minimal_geometry_consistent_correction_A15";
end

function selected = nearest_candidate(center_ab, candidates, vectors)
candidate_points = vectors.ab_V(candidates + 1, :);
distance = vecnorm(candidate_points - center_ab(:).', 2, 2);
minimum = min(distance);
ties = candidates(abs(distance - minimum) <= 10*eps(max(1, minimum)));
selected = min(ties); % deterministic tie break, ambiguity A08
end
