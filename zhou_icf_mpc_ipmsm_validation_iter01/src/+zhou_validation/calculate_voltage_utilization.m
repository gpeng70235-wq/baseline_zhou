function [samples,summary,audit] = calculate_voltage_utilization( ...
        voltage_input,dc_bus_V,voltage_vector_scale,saturation_threshold)
%CALCULATE_VOLTAGE_UTILIZATION Normalize dq voltage by inverter AVV radius.

if nargin<3 || isempty(voltage_vector_scale), voltage_vector_scale=2/3; end
if nargin<4 || isempty(saturation_threshold), saturation_threshold=.98; end
validateattributes(dc_bus_V,{'double'},{'scalar','positive','finite'});
validateattributes(voltage_vector_scale,{'double'}, ...
    {'scalar','positive','finite'});
validateattributes(saturation_threshold,{'double'}, ...
    {'scalar','positive','<=',1,'finite'});

if istable(voltage_input)
    [ud,uq,source_fields] = voltage_columns(voltage_input);
    key_candidates = ["run_id" "timestamp" "experiment" "scenario" ...
        "scenario_id" "cycle_index" "physical_time_s" "speed_rpm" ...
        "alpha_mode" "F_estimator"];
    present = key_candidates(ismember(key_candidates, ...
        string(voltage_input.Properties.VariableNames)));
    samples = voltage_input(:,cellstr(present));
else
    value = double(voltage_input);
    if size(value,2)==2
        dq=value;
    elseif size(value,1)==2
        dq=value.';
    else
        error('ZhouValidation:VoltageShape', ...
            'Numeric voltage input must be N-by-2 or 2-by-N dq data.');
    end
    ud=dq(:,1);uq=dq(:,2);source_fields="numeric_dq";
    samples=table();
end
assert(~isempty(ud) && all(isfinite([ud;uq])), ...
    'ZhouValidation:VoltageNonfinite','Voltage samples must be finite.');

limit_V = dc_bus_V*voltage_vector_scale;
magnitude_V = hypot(ud,uq);
utilization = magnitude_V/limit_V;
saturated = utilization >= saturation_threshold;

samples.voltage_d_V=ud;
samples.voltage_q_V=uq;
samples.voltage_magnitude_V=magnitude_V;
samples.voltage_limit_V=repmat(limit_V,numel(ud),1);
samples.voltage_utilization=utilization;
samples.saturation_flag=saturated;

summary=table(numel(ud),mean(utilization),quantile_local(utilization,.95), ...
    max(utilization),mean(saturated),max(magnitude_V),limit_V, ...
    'VariableNames',{'samples','mean_voltage_utilization', ...
    'p95_voltage_utilization','max_voltage_utilization', ...
    'saturation_cycle_fraction','max_voltage_magnitude_V', ...
    'voltage_limit_V'});

audit=struct('definition',"norm(u_dq)/(voltage_vector_scale*Vdc)", ...
    'voltage_source_fields',source_fields,'dc_bus_V',dc_bus_V, ...
    'voltage_vector_scale',voltage_vector_scale, ...
    'saturation_definition',"utilization >= saturation_threshold", ...
    'saturation_threshold',saturation_threshold);
end

function [ud,uq,names] = voltage_columns(T)
vars=string(T.Properties.VariableNames);
dc=["U4d_V" "u4_applied_d" "applied_u_d" "applied_voltage_d_V" ...
    "u_applied_d_V" "selected_voltage_d_V" "selected_u_d" ...
    "u_d_V" "ud_V"];
qc=["U4q_V" "u4_applied_q" "applied_u_q" "applied_voltage_q_V" ...
    "u_applied_q_V" "selected_voltage_q_V" "selected_u_q" ...
    "u_q_V" "uq_V"];
di=find(ismember(dc,vars),1);qi=find(ismember(qc,vars),1);
if ~isempty(di) && ~isempty(qi)
    dn=dc(di);qn=qc(qi);ud=double(T.(char(dn)));uq=double(T.(char(qn)));
    ud=ud(:);uq=uq(:);names=[dn;qn];return
end
mc=["u4_applied_dq" "applied_u_dq" "applied_voltage_dq" ...
    "selected_voltage_dq"];
mi=find(ismember(mc,vars),1);
if ~isempty(mi)
    mn=mc(mi);value=double(T.(char(mn)));
    assert(size(value,2)==2,'ZhouValidation:VoltageShape', ...
        '%s must be an N-by-2 dq matrix.',mn);
    ud=value(:,1);uq=value(:,2);names=mn;return
end
error('ZhouValidation:VoltageFields', ...
    ['No applied/selected dq voltage columns found. Vd/Vq controller ' ...
     'geometry terms are intentionally not treated as applied voltage.']);
end

function q=quantile_local(x,p)
x=sort(x(:));
if isscalar(x), q=x; return; end
position=1+(numel(x)-1)*p;
lo=floor(position);hi=ceil(position);
q=x(lo)+(position-lo)*(x(hi)-x(lo));
end
