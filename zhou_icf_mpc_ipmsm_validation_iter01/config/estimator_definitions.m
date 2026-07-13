function definitions = estimator_definitions(Ts)
%ESTIMATOR_DEFINITIONS Pre-registered estimator comparison settings.

if nargin < 1
    Ts = base_parameters().Ts_s;
end
definitions.algebraic = struct('name',"algebraic_iter11", ...
    'window_samples',5, 'online',true, 'role',"frozen_baseline");
definitions.eso_poles = [0.15 0.30 0.50];
template = struct('name',"basic_ESO",'pole',NaN, ...
    'omega0_rad_s',NaN,'beta01',NaN,'beta02',NaN, ...
    'online',true,'role',"comparison_only");
definitions.eso = repmat(template,numel(definitions.eso_poles),1);
for k = 1:numel(definitions.eso_poles)
    pole = definitions.eso_poles(k);
    omega0 = (1-pole)/Ts;
    definitions.eso(k) = struct('name',"basic_ESO",'pole',pole, ...
        'omega0_rad_s',omega0,'beta01',2*omega0*Ts, ...
        'beta02',omega0^2*Ts,'online',true,'role',"comparison_only");
end
definitions.oracle = struct('name',"interval_oracle_offline", ...
    'online',false,'role',"noncausal_offline_lower_bound");
end
