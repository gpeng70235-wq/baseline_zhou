function output = icf_mpc_step(current_dq, previous_current_dq, ...
        last_applied_voltage_dq, pending_command, reference_dq, theta_e, ...
        omega_e, cfg, history_valid)
%ICF_MPC_STEP Independent-current-constraint MPC adapted for an IPMSM.
% Geometry, Case 1/2/3 selection, dwell synthesis, and the execution-frame
% patch follow the Iteration 11 flow. Only the two alpha axes and plant are
% specialized for Ld ~= Lq.

if strcmp(cfg.alpha_mode,'axis_specific')
    alpha_dq = [1/cfg.motor.Ld; 1/cfg.motor.Lq];
else
    alpha_dq = ones(2,1)/mean([cfg.motor.Ld cfg.motor.Lq]);
end
Fhat = zhou_ipmsm.controller.estimate_ultralocal_F(current_dq, ...
    previous_current_dq,last_applied_voltage_dq,alpha_dq,cfg.Ts,history_valid);

vectors = zhou_ipmsm.inverter.voltage_vectors(cfg.Vdc);
pending_voltage_dq = zhou_ipmsm.controller.sequence_equivalent_dq_voltage( ...
    pending_command,vectors,theta_e,omega_e,0,cfg.Ts,cfg.assumptions.frame_mode);
% Equations (3), (6), and (8): account for the command pending execution in
% this period, then select a command for the following period.
predicted_k1 = zhou_ipmsm.controller.predict_current(current_dq,Fhat, ...
    pending_voltage_dq,alpha_dq,cfg.Ts);
V_dq = reference_dq(:)-predicted_k1-cfg.Ts*Fhat;
geometry_theta = theta_e;
if strcmp(cfg.assumptions.frame_mode,'execution_segment_midpoint')
    geometry_theta = mod(theta_e+1.5*omega_e*cfg.Ts,2*pi);
end
rectangle = zhou_ipmsm.geometry.build_voltage_rectangle(V_dq, ...
    [cfg.Jd_limit;cfg.Jq_limit],alpha_dq,cfg.Ts,geometry_theta);
classification = zhou_ipmsm.geometry.classify_case(rectangle);
selection = struct();

switch classification.case_id
    case 1
        requested_ab = [0 0];
    case 2
        [requested_ab,selection] = select_case2_midpoint( ...
            classification,rectangle.center_ab,vectors);
    case 3
        requested_ab = rectangle.center_ab;
end
selected_vector = [];
if isfield(selection,'vector_id')
    selected_vector = selection.vector_id;
end
command = zhou_ipmsm.modulation.generate_case_sequence(requested_ab,cfg.Ts, ...
    vectors,1e-10,classification.case_id,selected_vector);
command.reference_dq_at_selection = ...
    zhou_ipmsm.inverter.park(command.reference_ab_V,theta_e);
selected_voltage_dq = zhou_ipmsm.controller.sequence_equivalent_dq_voltage( ...
    command,vectors,theta_e,omega_e,1,cfg.Ts,cfg.assumptions.frame_mode);
predicted_k2 = zhou_ipmsm.controller.predict_current(predicted_k1,Fhat, ...
    selected_voltage_dq,alpha_dq,cfg.Ts);
axis_cost = (reference_dq(:)-predicted_k2).^2;

geometry = struct('rectangle',rectangle,'classification',classification, ...
    'selection',selection, ...
    'requested_reference_ab_V',requested_ab, ...
    'synthesized_reference_inside_rectangle', ...
    zhou_ipmsm.geometry.validate_candidate_geometry(command,cfg.Ts,rectangle,1e-8));
output = struct('command',command,'voltage_dq',selected_voltage_dq, ...
    'Fhat',Fhat,'predicted_k1_dq',predicted_k1,'predicted_k2_dq',predicted_k2, ...
    'pending_voltage_dq_used',pending_voltage_dq, ...
    'V_dq',V_dq,'Jd',axis_cost(1),'Jq',axis_cost(2), ...
    'constraint_satisfied_d',axis_cost(1)<=cfg.Jd_limit+1e-12, ...
    'constraint_satisfied_q',axis_cost(2)<=cfg.Jq_limit+1e-12, ...
    'cost',sum(axis_cost),'alpha_dq',alpha_dq,'geometry',geometry, ...
    'geometry_theta',geometry_theta);
end

function [point,selection] = select_case2_midpoint(classification,center_ab,vectors)
% Iteration 11 Table-I policy with its documented minimal sector corrections.
[sector,boundary] = sector_of_point(center_ab);
code = sprintf('%d%d%d',classification.line_hits);
correction = false;
fallback = false;
switch code
    case '100'
        candidates = [1 4];
        if ismember(sector,[1 6]), vector_id=1; correction=sector==6;
        elseif ismember(sector,[3 4]), vector_id=4; correction=sector==4;
        else, vector_id=nearest_candidate(center_ab,candidates,vectors); fallback=true; end
    case '010'
        candidates = [2 5];
        if ismember(sector,[1 2]), vector_id=2;
        elseif ismember(sector,[4 5]), vector_id=5;
        else, vector_id=nearest_candidate(center_ab,candidates,vectors); fallback=true; end
    case '001'
        candidates = [3 6];
        if ismember(sector,[2 3]), vector_id=3;
        elseif ismember(sector,[5 6]), vector_id=6;
        else, vector_id=nearest_candidate(center_ab,candidates,vectors); fallback=true; end
    case '110'
        candidates = [1 5];
        if ismember(sector,[1 2 6]), vector_id=1; else, vector_id=5; end
    case '011'
        candidates = [3 5];
        if ismember(sector,[1 2 3]), vector_id=3; else, vector_id=5; end
    case '101'
        candidates = [3 1];
        if ismember(sector,[2 3 4]), vector_id=3; correction=ismember(sector,[2 3]);
        else, vector_id=1; end
    case '111'
        candidates = 1:6;
        vector_id = nearest_candidate(center_ab,candidates,vectors);
    otherwise
        error('ZhouIPMSM:InvalidTableIInput','Case 2 line code %s is invalid.',code);
end
line_id = [1 2 3 1 2 3];
intersection = classification.intersections(line_id(vector_id));
assert(intersection.hit && ~isempty(intersection.midpoint_ab), ...
    'ZhouIPMSM:Case2Intersection','Selected active-vector line has no segment.');
point = intersection.midpoint_ab;
active = vectors.ab_V(vector_id+1,:);
phase_flip = dot(point,active)<0;
if phase_flip
    vector_id = mod(vector_id+2,6)+1;
end
selection = struct('vector_id',vector_id,'sector',sector, ...
    'sector_boundary',boundary,'line_code',string(code),'candidates',candidates, ...
    'table_I_correction_used',correction,'fallback_used',fallback, ...
    'phase_feasibility_flip',phase_flip, ...
    'midpoint_method',"geometric_paper_prose_Table_II_crosscheck_replacement");
end

function selected = nearest_candidate(center_ab,candidates,vectors)
distances = vecnorm(vectors.ab_V(candidates+1,:)-center_ab,2,2);
minimum = min(distances);
ties = candidates(abs(distances-minimum)<=10*eps(max(1,minimum)));
selected = min(ties);
end

function [sector,boundary] = sector_of_point(point)
angle = mod(atan2(point(2),point(1)),2*pi);
scaled = angle/(pi/3);
nearest = round(scaled);
boundary = abs(scaled-nearest)<=1e-12;
if boundary
    sector = mod(nearest,6)+1;
else
    sector = floor(scaled)+1;
end
end
