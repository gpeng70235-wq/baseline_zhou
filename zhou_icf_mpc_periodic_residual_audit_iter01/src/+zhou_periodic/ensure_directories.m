function ensure_directories(cfg)
dirs = {cfg.audit_dir, cfg.docs_dir, cfg.summary_dir, cfg.figure_dir, ...
    cfg.cache_dir, fileparts(cfg.canonical_csv), cfg.reference_dir, ...
    fileparts(cfg.frozen_model_error_csv)};
for k = 1:numel(dirs)
    if ~isfolder(dirs{k}), mkdir(dirs{k}); end
end
end
