function [oracle,audit] = calculate_F_interval_oracle(trace,alpha_dq,Ts)
%CALCULATE_F_INTERVAL_ORACLE Reconstruct effective interval F offline.
% F_interval = (i_end-i_start)/Ts - alpha .* u_interval.
% The endpoint at the end of the interval is a future measurement relative
% to the decision that selected u_interval. Consequently this function is a
% validation oracle and is prohibited from every online controller path.

arguments
    trace table
    alpha_dq double
    Ts (1,1) double {mustBePositive,mustBeFinite}
end
assert(height(trace)>=1,'ZhouValidation:OracleTrace', ...
    'Interval oracle requires a nonempty trace.');

[start_d,start_q,start_names] = find_pair(trace, ...
    ["plant_id_k1_A" "id_plant_k1" "id_actual_k1" "id_k1" "id_A_k1"], ...
    ["plant_iq_k1_A" "iq_plant_k1" "iq_actual_k1" "iq_k1" "iq_A_k1"]);
[end_d,end_q,end_names] = find_pair(trace, ...
    ["plant_id_k2_A" "id_plant_k2" "id_actual_k2" "id_k2" "id_A_k2"], ...
    ["plant_iq_k2_A" "iq_plant_k2" "iq_actual_k2" "iq_k2" "iq_A_k2"]);

explicit_endpoints = ~isempty(start_d) && ~isempty(end_d);
if explicit_endpoints
    row_index = (1:height(trace)).';
else
    [id,iq,current_names] = find_pair(trace,["id_A" "id"], ...
        ["iq_A" "iq"]);
    assert(~isempty(id) && height(trace)>=2, ...
        'ZhouValidation:OracleEndpointFields', ...
        ['Provide explicit k+1/k+2 plant endpoints or sequential ' ...
         'id_A/iq_A samples.']);
    start_d = id(1:end-1); start_q = iq(1:end-1);
    end_d = id(2:end); end_q = iq(2:end);
    start_names = current_names+"(row k)";
    end_names = current_names+"(row k+1)";
    row_index = (1:height(trace)-1).';
end
n = numel(start_d);

[ud,uq,voltage_names] = find_pair(trace, ...
    ["U4d_V" "u4_applied_d" "applied_u_d" "applied_voltage_d_V" ...
     "u_applied_d_V" "u_d_V" "ud_V"], ...
    ["U4q_V" "u4_applied_q" "applied_u_q" "applied_voltage_q_V" ...
     "u_applied_q_V" "u_q_V" "uq_V"]);
if isempty(ud)
    [u_matrix,voltage_names] = find_matrix(trace, ...
        ["u4_applied_dq" "applied_u_dq" "applied_voltage_dq"]);
    if ~isempty(u_matrix)
        ud = u_matrix(:,1); uq = u_matrix(:,2);
    end
end
assert(~isempty(ud),'ZhouValidation:OracleVoltageFields', ...
    ['Trace must contain the dq average voltage for the reconstructed ' ...
     'interval (prefer u4_applied_d/q).']);
if numel(ud)==height(trace)
    ud = ud(row_index); uq = uq(row_index);
elseif numel(ud)~=n
    error('ZhouValidation:OracleVoltageLength', ...
        'Voltage rows do not align with the reconstructed intervals.');
end

alpha = normalize_alpha(alpha_dq,trace,row_index,n);
source_interval_rows=n;
valid=isfinite(start_d) & isfinite(start_q) & isfinite(end_d) & ...
    isfinite(end_q) & isfinite(ud) & isfinite(uq) & ...
    all(isfinite(alpha),2);
assert(any(valid),'ZhouValidation:OracleNonfinite', ...
    'No complete finite endpoint/voltage interval is available.');
row_index=row_index(valid);
start_d=start_d(valid);start_q=start_q(valid);
end_d=end_d(valid);end_q=end_q(valid);
ud=ud(valid);uq=uq(valid);alpha=alpha(valid,:);
n=nnz(valid);

Fd = (end_d-start_d)/Ts-alpha(:,1).*ud;
Fq = (end_q-start_q)/Ts-alpha(:,2).*uq;
reconstructed_d = start_d+Ts*(Fd+alpha(:,1).*ud);
reconstructed_q = start_q+Ts*(Fq+alpha(:,2).*uq);

key_candidates = ["run_id" "timestamp" "experiment" "scenario" ...
    "scenario_id" "cycle_index" "physical_time_s" "speed_rpm" ...
    "id_reference" "id_ref" "iq_reference" "iq_ref" "alpha_mode" ...
    "F_estimator"];
present = key_candidates(ismember(key_candidates, ...
    string(trace.Properties.VariableNames)));
oracle = trace(row_index,cellstr(present));
oracle.interval_start_id_A = start_d;
oracle.interval_start_iq_A = start_q;
oracle.interval_end_id_A = end_d;
oracle.interval_end_iq_A = end_q;
oracle.interval_ud_V = ud;
oracle.interval_uq_V = uq;
oracle.alpha_d = alpha(:,1);
oracle.alpha_q = alpha(:,2);
oracle.Fd_interval = Fd;
oracle.Fq_interval = Fq;
oracle.oracle_online = false(n,1);
oracle.uses_future_endpoint = true(n,1);

audit = struct();
audit.name = "interval_F_oracle_offline";
audit.online = false;
audit.noncausal = true;
audit.uses_future_endpoint = true;
audit.rows = n;
audit.source_interval_rows = source_interval_rows;
audit.dropped_incomplete_rows = source_interval_rows-n;
audit.Ts_s = Ts;
audit.endpoint_mode = conditional_text(explicit_endpoints, ...
    "explicit_k1_k2_columns","successive_trace_rows");
audit.start_fields = start_names;
audit.end_fields = end_names;
audit.voltage_fields = voltage_names;
audit.max_reconstruction_error_A = max(abs([reconstructed_d-end_d; ...
    reconstructed_q-end_q]));
audit.identity = ...
    "i_end = i_start + Ts*(F_interval + alpha.*u_interval)";
end

function alpha = normalize_alpha(alpha_dq,trace,row_index,n)
if isempty(alpha_dq)
    [ad,aq] = find_pair(trace,"alpha_d","alpha_q");
    assert(~isempty(ad),'ZhouValidation:OracleAlpha', ...
        'Supply alpha_dq or alpha_d/alpha_q trace columns.');
    alpha = [ad(row_index),aq(row_index)];
elseif isvector(alpha_dq) && numel(alpha_dq)==2
    alpha = repmat(alpha_dq(:).',n,1);
elseif isequal(size(alpha_dq),[n,2])
    alpha = alpha_dq;
elseif isequal(size(alpha_dq),[2,n])
    alpha = alpha_dq.';
elseif size(alpha_dq,1)==height(trace) && size(alpha_dq,2)==2
    alpha = alpha_dq(row_index,:);
else
    error('ZhouValidation:OracleAlpha', ...
        'alpha_dq must be a two-vector or one d/q pair per interval.');
end
assert(all(isfinite(alpha),'all') && all(alpha>0,'all'), ...
    'ZhouValidation:OracleAlpha','alpha_dq must be finite and positive.');
end

function [d,q,names] = find_pair(T,d_candidates,q_candidates)
d=[];q=[];names=strings(0,1);
vars=string(T.Properties.VariableNames);
di=find(ismember(d_candidates,vars),1);
qi=find(ismember(q_candidates,vars),1);
if isempty(di) || isempty(qi), return; end
dn=d_candidates(di);qn=q_candidates(qi);
d=double(T.(char(dn)));q=double(T.(char(qn)));
d=d(:);q=q(:);names=[dn;qn];
end

function [value,names] = find_matrix(T,candidates)
value=[];names=strings(0,1);vars=string(T.Properties.VariableNames);
idx=find(ismember(candidates,vars),1);
if isempty(idx), return; end
name=candidates(idx);value=double(T.(char(name)));
assert(size(value,2)==2,'ZhouValidation:OracleVoltageShape', ...
    '%s must be an N-by-2 dq matrix.',name);
names=name;
end

function value = conditional_text(condition,if_true,if_false)
if condition, value=if_true; else, value=if_false; end
end
