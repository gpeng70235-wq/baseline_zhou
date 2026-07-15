function outcome = run_periodic_residual_audit(mode)
%RUN_PERIODIC_RESIDUAL_AUDIT Reproducible periodic-residual diagnostic audit.
%   run_periodic_residual_audit() is equivalent to ('all'). Supported modes:
%   inventory, baseline, data, spectrum, order, phase, false_safe,
%   counterfactual, audit, all.

if nargin < 1 || strlength(string(mode)) == 0
    mode = "all";
end
mode = lower(string(mode));
valid = ["inventory","baseline","data","spectrum","order","phase", ...
    "false_safe","counterfactual","audit","all"];
assert(isscalar(mode) && any(mode == valid), ...
    'Unsupported mode. Use: %s.', strjoin(valid, ', '));

root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'config'));
addpath(fullfile(root, 'src'));
cfg = periodic_audit_config(root);
zhou_periodic.ensure_directories(cfg);

stage = find(valid == mode, 1);
if mode == "all"
    stage = find(valid == "audit", 1);
end

fprintf('\nZhou ICF-MPC periodic residual audit: %s\n', mode);
fprintf('Project: %s\n', cfg.root);

outcome = struct('mode', mode, 'project_root', string(cfg.root), ...
    'completed_stage', "none", 'decision_code', "NOT_EVALUATED");

% Phase 0: upstream inventory, freeze and duplicate-work guard.
zhou_periodic.inventory(cfg);
outcome.completed_stage = "inventory";
if stage == 1, return; end

% Phase 1: source-data gate and canonical one-row-per-prediction dataset.
zhou_periodic.baseline(cfg);
outcome.completed_stage = "baseline";
if stage == 2, return; end

% Phases 2--7. Each call is deterministic and writes registered artifacts.
target = mode;
if mode == "all" || mode == "audit", target = "counterfactual"; end
zhou_periodic.analysis_pipeline(cfg, target);
outcome.completed_stage = target;
if stage < 9, return; end

% Phases 8--9: decision, figures, documentation, and AFTER hash assertion.
decision = zhou_periodic.finalize(cfg);
outcome.completed_stage = "audit";
outcome.decision_code = string(decision.decision_code(1));
fprintf('Audit complete: decision %s, prototype authorized = %d\n', ...
    outcome.decision_code, decision.prototype_authorized(1));
end
