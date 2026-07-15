function cfg = periodic_audit_config(root)
%PERIODIC_AUDIT_CONFIG Frozen preregistration and path resolution rules.

cfg = struct();
cfg.root = char(root);
cfg.parent = fileparts(cfg.root);
cfg.audit_version = "periodic_residual_audit_iter01_v1";
cfg.matlab_release = "R2024b";
cfg.random_seed = 20260715;
cfg.Ts_s = 1e-4;
cfg.fs_Hz = 1/cfg.Ts_s;
cfg.Jd_limit_A2 = 0.16;
cfg.Jq_limit_A2 = 0.16;
cfg.constraint_tolerance_A2 = 1e-12;
cfg.expected_cases = 24;
cfg.expected_samples = 24153;
cfg.expected_primary_false_safe = 0.03029663698890;
cfg.expected_all_false_safe = 0.03059661325715;
cfg.expected_early_terminations = 5;
cfg.baseline_rate_tolerance = 5e-12;
cfg.numeric_tolerance = 2e-10;

cfg.preregistered_orders = [6 12];
cfg.display_orders = 1:20;
cfg.angle_points_per_cycle = 256;
cfg.minimum_cycles = 3;
cfg.maximum_speed_cv = 0.01;
cfg.minimum_peak_snr_db = 6;
cfg.maximum_amplitude_cv = 0.30;
cfg.minimum_phase_R = 0.70;
cfg.minimum_stable_primary_cases = 3;
cfg.minimum_false_safe_reduction = 0.20;
cfg.maximum_false_alarm_increase_pp = 0.5;
cfg.minimum_rms_reduction = 0.10;
cfg.event_pre_samples = 10;
cfg.event_post_samples = 10;
cfg.phase_bin_count = 24;

cfg.prototype_name = "zhou_icf_mpc_periodic_compensation_prototype_iter01";
cfg.branch_name = "codex/zhou-periodic-residual-audit-iter01";

proto = fullfile(cfg.parent, 'zhou_icf_mpc_dual_timescale_prototype_iter01');
model_snapshot = fullfile(proto, 'reference', 'upstream_snapshots', ...
    'zhou_icf_mpc_model_error_decomposition_iter01');
cfg.prototype_project = proto;
cfg.model_error_snapshot = model_snapshot;
cfg.source_model_error_csv = fullfile(model_snapshot, 'results', 'raw', ...
    'model_error_samples.csv');
cfg.source_prototype_b0_csv = fullfile(proto, 'results', 'raw', ...
    'closed_loop_samples_B0.csv');
cfg.frozen_model_error_csv = fullfile(cfg.root, 'reference', 'frozen_data', ...
    'model_error_samples.csv');
cfg.frozen_prototype_b0_csv = fullfile(cfg.root, 'reference', 'frozen_data', ...
    'prototype_closed_loop_samples_B0.csv');
cfg.canonical_csv = fullfile(cfg.root, 'results', 'raw', ...
    'periodic_residual_samples.csv');

cfg.required_source_fields = ["case_id","case_category","range_class", ...
    "sample_index","time_s","speed_rpm","electrical_speed", ...
    "electrical_angle","id","iq","id_actual","iq_actual","id_ref", ...
    "iq_ref","id_pred_P0","iq_pred_P0","Jd_P0","Jq_P0", ...
    "Jd_actual","Jq_actual","false_safe_P0","false_alarm_P0", ...
    "actual_joint_pass","mode","S2_triggered","voltage_utilization", ...
    "pending_u_d","pending_u_q","selected_u_d","selected_u_q", ...
    "applied_sequence_vector_ids","applied_sequence_durations_s", ...
    "phase","reference_rate_A_s","distance_to_Jd_boundary", ...
    "distance_to_Jq_boundary","ed_P0","eq_P0","P0_recompute_gap_A", ...
    "P5_replay_gap_A"];

cfg.summary_dir = fullfile(cfg.root, 'results', 'summary');
cfg.figure_dir = fullfile(cfg.root, 'results', 'figures');
cfg.cache_dir = fullfile(cfg.root, 'results', 'cache');
cfg.docs_dir = fullfile(cfg.root, 'docs');
cfg.audit_dir = fullfile(cfg.root, 'audit');
cfg.reference_dir = fullfile(cfg.root, 'reference', 'frozen_evidence');
end
