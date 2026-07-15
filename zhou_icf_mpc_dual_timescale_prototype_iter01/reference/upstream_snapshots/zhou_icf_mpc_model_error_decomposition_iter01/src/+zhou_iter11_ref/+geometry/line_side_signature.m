function signature = line_side_signature(rect, vector_id, tolerance)
%LINE_SIDE_SIGNATURE Paper equation (13) sym(a/b/c/d) and K.

if nargin < 3
    tolerance = rect.tolerance;
end
if ismember(vector_id, [1, 4])
    line_id = 1;
elseif ismember(vector_id, [2, 5])
    line_id = 2;
elseif ismember(vector_id, [3, 6])
    line_id = 3;
else
    error('ZhouIter11Ref:InvalidActiveVector', 'Expected V1...V6, got V%d.', vector_id);
end

lines = zhou_iter11_ref.geometry.active_lines();
normal = lines.coefficients(line_id, :);
normal = normal / norm(normal);
values = rect.corners_ab * normal.';
sym_values = double(values >= -tolerance); % tolerance-aware sgn(0)=1

signature = struct();
signature.line_id = line_id;
signature.values = values;
signature.sym = sym_values;
signature.K = sum(sym_values);
signature.vertex_on_line = any(abs(values) <= tolerance);
end
