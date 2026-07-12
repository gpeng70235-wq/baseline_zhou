function pass = experiment_P0_degenerate_regression(cfg, run_id)
%EXPERIMENT_P0_DEGENERATE_REGRESSION Ld=Lq analytical SMPMSM limit.
cfg.motor.Ld = cfg.experiments.P0.Ld;
cfg.motor.Lq = cfg.experiments.P0.Lq;
cfg.id_ref = cfg.experiments.P0.id;
[project_root,~,~] = fileparts(fileparts(mfilename('fullpath')));
targets = readtable(fullfile(project_root,'reference','iter11_regression_targets.csv'), ...
    'TextType','string');
[metrics,trace] = zhou_ipmsm.run_probe_case(cfg);
metrics.reduction_residual_Nm = abs(metrics.mean_reluctance_torque_Nm);
[derivative_residual,torque_residual] = smpmsm_oracle_residual(cfg);
metrics.max_smpmsm_derivative_residual_A_per_s = derivative_residual;
metrics.max_smpmsm_torque_residual_Nm = torque_residual;
target_contract_pass = cfg.motor.Ld==target_value(targets,'Ld_equals_Lq_H') && ...
    cfg.motor.Lq==target_value(targets,'Ld_equals_Lq_H') && ...
    cfg.id_ref==target_value(targets,'id_reference_A');
metrics.iter11_target_contract_pass = target_contract_pass;
metrics.iter11_target_count = height(targets);
pass = common_acceptance(metrics,cfg.acceptance) && ...
    metrics.reduction_residual_Nm <= cfg.acceptance.reduction && ...
    derivative_residual<=cfg.acceptance.equation && ...
    torque_residual<=cfg.acceptance.reduction && target_contract_pass;
zhou_ipmsm.io.save_experiment_result(cfg,run_id,'regression',metrics,trace,pass);
end

function [derivative_residual,torque_residual] = smpmsm_oracle_residual(cfg)
states = [-8 -2 0 3; 2 10 -4 7];
voltages = [-15 0 8 20; 4 -9 12 0];
omega = cfg.speed_rpm*2*pi/60*cfg.motor.pole_pairs;
derivative_residual = 0;
torque_residual = 0;
L = cfg.motor.Ld;
for index = 1:size(states,2)
    state = states(:,index);
    voltage = voltages(:,index);
    actual = zhou_ipmsm.model.ipmsm_dq_dynamics(state,voltage,omega,cfg.motor);
    expected = [(voltage(1)-cfg.motor.Rs*state(1)+omega*L*state(2))/L; ...
        (voltage(2)-cfg.motor.Rs*state(2)-omega*(L*state(1)+cfg.motor.psi_f))/L];
    derivative_residual = max(derivative_residual,max(abs(actual-expected)));
    expected_torque = 1.5*cfg.motor.pole_pairs*cfg.motor.psi_f*state(2);
    actual_torque = zhou_ipmsm.model.calculate_ipmsm_torque(state,cfg.motor);
    torque_residual = max(torque_residual,abs(actual_torque-expected_torque));
end
end

function value = target_value(targets,name)
row = targets.target==string(name);
assert(nnz(row)==1,'ZhouIPMSM:RegressionTarget','Missing or duplicate target %s.',name);
value = targets.value(row);
end

function pass = common_acceptance(metrics,thresholds)
pass = metrics.illegal_commands<=thresholds.max_illegal && ...
    metrics.negative_durations==0 && ...
    metrics.constraint_d_violations<=thresholds.max_constraint_violations && ...
    metrics.constraint_q_violations<=thresholds.max_constraint_violations && ...
    metrics.geometry_reference_outside<=thresholds.max_geometry_outside && ...
    metrics.saturated_commands<=thresholds.max_saturated_commands && ...
    max([metrics.rmse_d_A metrics.rmse_q_A])<=thresholds.max_rmse_A && ...
    metrics.phase_a_thd<=thresholds.max_phase_a_thd;
end
