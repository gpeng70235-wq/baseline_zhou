function experiments = experiment_definitions()
%EXPERIMENT_DEFINITIONS Four ordered admission experiments.
experiments.P0 = struct('Ld',1e-3,'Lq',1e-3,'id',0);
experiments.P1 = struct('Ld',0.8e-3,'Lq',1.2e-3,'id',0);
experiments.alpha_modes = {'axis_specific','common_Ls'};
experiments.negative_id = [0 -2 -4 -6];
end
