function scenarios=sequence_scenarios(project)
%SEQUENCE_SCENARIOS Pre-registered minimal representative set; not a broad scan.
% Categories are normal, reasonable_extension, and stress_test as requested.

rows={ ...
"C01_nominal_100rpm_10A", "core", "normal",100,0,10,48,"ramp",.005,1,1;
"C02_light_100rpm_4A",    "core", "normal",100,0,4,48,"ramp",.010,1,1;
"C03_light_200rpm_6A",    "core", "normal",200,0,6,48,"ramp",.008,1,1;
"C04_high_200rpm_18A",    "core", "normal",200,0,18,48,"ramp",.005,1,1;
"C05_negative_id",        "core", "reasonable_extension",300,-4,15,48,"ramp",.007,1,1;
"C06_low_bus_43p2V",      "core", "reasonable_extension",300,0,15,43.2,"ramp",.006,1,1;
"C07_known_false_safe",   "core", "normal",500,0,20,48,"ramp",.003,1,1;
"C08_S2_nontrigger",      "core", "normal",100,0,10,48,"constant",.005,1,1;
"C09_S2_boundary",        "core", "normal",500,0,20,48,"ramp",.005,1,1;
"D01_iq_step",            "dynamic", "normal",300,0,18,48,"two_step",.003,1,1;
"D02_id_step",            "dynamic", "reasonable_extension",300,-5,0,48,"two_step",.003,1,1;
"D03_id_iq_step",         "dynamic", "reasonable_extension",300,-4,16,48,"two_step",.003,1,1;
"D04_torque_ramp",        "dynamic", "normal",400,0,18,48,"ramp",.015,1,1;
"D05_torque_step",        "dynamic", "normal",400,0,18,48,"two_step",.002,1,1;
"P01_Ld_minus10",         "parameter", "reasonable_extension",300,0,18,48,"ramp",.006,.9,1;
"P02_Ld_plus10",          "parameter", "reasonable_extension",300,0,18,48,"ramp",.006,1.1,1;
"P03_Lq_minus10",         "parameter", "reasonable_extension",300,0,18,48,"ramp",.006,1,.9;
"P04_Lq_plus10",          "parameter", "reasonable_extension",300,0,18,48,"ramp",.006,1,1.1;
"P05_cross_mismatch",     "parameter", "reasonable_extension",400,0,18,48,"ramp",.005,.9,1.1;
"P06_controller_high_L",  "parameter", "reasonable_extension",400,0,18,48,"ramp",.005,.8,.8;
"P07_controller_low_L",   "parameter", "reasonable_extension",400,0,18,48,"ramp",.005,1.2,1.2;
"P08_opposed_20pct",      "parameter", "reasonable_extension",400,-3,17,48,"ramp",.005,1.2,.8;
"B01_500rpm_20A_48V_fast","boundary", "stress_test",500,0,20,48,"ramp",.002,1,1;
"B02_500rpm_negid_48V",   "boundary", "stress_test",500,-4,sqrt(384),48,"two_step",.002,1,1};

template=control_scenario(project);
scenarios=struct([]);
for k=1:size(rows,1)
    s=template;
    s.name=string(rows{k,1});s.scenario_id=s.name;
    s.case_category=string(rows{k,2});s.range_class=string(rows{k,3});
    s.speed_rpm=rows{k,4};s.id_ref_A=rows{k,5};s.iq_ref_A=rows{k,6};
    s.dc_bus_V=rows{k,7};s.profile_type=string(rows{k,8});
    s.reference_profile=s.profile_type;s.reference_ramp_s=rows{k,9};
    s.plant_Ld_scale=rows{k,10};s.plant_Lq_scale=rows{k,11};
    s.simulation_time_s=project.sequence.simulation_time_s;
    s.steady_window_start_s=project.sequence.steady_window_start_s;
    s.integration_step_s=project.sequence.decomposition_integration_step_s;
    s.Jd_limit_A2=project.sequence.Jd_limit_A2;
    s.Jq_limit_A2=project.sequence.Jq_limit_A2;
    s.alpha_mode="axis_specific";s.F_estimator="algebraic_iter11";
    s.current_step_time_s=0.045;s.random_seed=project.sequence.random_seed+k;
    s.measurement_noise_std_A=0;s.angle_error_deg=0;s.dead_time_s=0;
    s.voltage_drop_V=0;s.split="representative_audit";
    if k==1,scenarios=s;else,scenarios(end+1)=s;end %#ok<AGROW>
end
end
