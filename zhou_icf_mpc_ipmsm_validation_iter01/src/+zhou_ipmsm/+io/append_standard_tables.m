function append_standard_tables(ctx,metrics,case_stats,violations)
%APPEND_STANDARD_TABLES Append common result tables within run and project ledger.

if ~isempty(metrics)
    zhou_ipmsm.io.write_or_append_table(fullfile(ctx.results_dir,'metrics.csv'),metrics);
    zhou_ipmsm.io.write_or_append_table(fullfile(ctx.results_root,'metrics.csv'),metrics);
end
if ~isempty(case_stats)
    zhou_ipmsm.io.write_or_append_table(fullfile(ctx.results_dir,'case_statistics.csv'),case_stats);
    zhou_ipmsm.io.write_or_append_table(fullfile(ctx.results_root,'case_statistics.csv'),case_stats);
end
if ~isempty(violations)
    zhou_ipmsm.io.write_or_append_table(fullfile(ctx.results_dir,'constraint_violations.csv'),violations);
    zhou_ipmsm.io.write_or_append_table(fullfile(ctx.results_root,'constraint_violations.csv'),violations);
end
end

