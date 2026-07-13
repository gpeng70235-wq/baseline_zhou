function [project, scenario] = validation_test_fixture(model)
%VALIDATION_TEST_FIXTURE Small deterministic configuration for unit tests.

if nargin < 1, model = "P1"; end
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
base = base_parameters();
motor = ipmsm_parameters();
assumptions = implementation_assumptions();
project = struct();
project.root = root;
project.run_id = "unit_test_run";
project.timestamp = "2000-01-01T00:00:00.000+00:00";
project.base = base;
project.paper = motor;
project.motor = motor;
project.nominal_motor = motor;
project.assumptions = assumptions;
project.thresholds = acceptance_thresholds();
project.estimators = estimator_definitions(base.Ts_s);
project.experiments = experiment_matrix(base);

scenario = project.experiments(1);
scenario.name = 'unit_short';
scenario.reference_profile = "constant";
scenario.simulation_time_s = 3e-3;
scenario.steady_window_start_s = 1e-3;
scenario.integration_step_s = 2e-6;
scenario.speed_rpm = 100;
scenario.id0_A = 0;
scenario.iq0_A = 2;
scenario.id_ref_A = 0;
scenario.iq_ref_A = 2;
scenario.F_estimator = "algebraic_iter11";
scenario.eso_pole = NaN;
scenario.motor_model = string(model);
scenario.plant_Ld_scale = 1;
scenario.plant_Lq_scale = 1;
scenario.plant_Rs_scale = 1;
scenario.plant_psi_f_scale = 1;
if string(model)=="P0"
    scenario.controller_alpha_d = 1/motor.Ls_H;
    scenario.controller_alpha_q = 1/motor.Ls_H;
    project.paper.alpha_d = scenario.controller_alpha_d;
    project.paper.alpha_q = scenario.controller_alpha_q;
else
    scenario.controller_alpha_d = 1/motor.Ld_H;
    scenario.controller_alpha_q = 1/motor.Lq_H;
    project.paper.alpha_d = scenario.controller_alpha_d;
    project.paper.alpha_q = scenario.controller_alpha_q;
end
end
