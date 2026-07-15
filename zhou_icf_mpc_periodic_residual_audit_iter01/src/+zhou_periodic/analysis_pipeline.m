function analysis_pipeline(cfg, target)
%ANALYSIS_PIPELINE Execute deterministic diagnostic phases through TARGET.
levels = containers.Map( ...
    {'data','spectrum','order','phase','false_safe','counterfactual'}, ...
    {1,2,3,4,5,6});
assert(isKey(levels,char(target)), 'Unsupported analysis target: %s', target);
level = levels(char(target));
T = readtable(cfg.canonical_csv, 'TextType','string');
[W, split] = zhou_periodic.select_windows(cfg, T);
if level == 1, return; end
S = zhou_periodic.spectrum_analysis(cfg, T, W);
if level == 2, return; end
C = zhou_periodic.order_analysis(cfg, T, W, split);
if level == 3, return; end
R = zhou_periodic.phase_analysis(cfg, T, W, split, C, S);
if level == 4, return; end
zhou_periodic.false_safe_analysis(cfg, T, W, split);
if level == 5, return; end
zhou_periodic.counterfactual_analysis(cfg, T, W, split, R);
end
