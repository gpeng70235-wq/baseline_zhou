function generate_inheritance_mapping(project)
%GENERATE_INHERITANCE_MAPPING Write a complete per-file source mapping.

snapshot=fullfile(project.root,'reference','iter11','source_snapshot','+zhou');
files=dir(fullfile(snapshot,'**','*.m'));
fid=fopen(fullfile(project.root,'docs','baseline_inheritance_mapping.md'),'w','n','UTF-8');
assert(fid>=0);cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'# Baseline inheritance mapping\n\n');
fprintf(fid,['Iteration 11 is treated as a fixed validation source snapshot, not as an ' ...
    'authority freeze. The snapshot below is never added to the MATLAB path.\n\n']);
fprintf(fid,'| source file | new project file | class | reason |\n|---|---|---|---|\n');
for k=1:numel(files)
    source=fullfile(files(k).folder,files(k).name);
    rel=replace(erase(string(source),string(snapshot)+filesep),filesep,'/');
    ref_target="src/+zhou_iter11_ref/"+rel;
    ipm_target="src/+zhou_ipmsm/"+rel;
    ref_reason="package namespace adapted; controller math frozen";
    if rel=="+sim/run_closed_loop.m",ref_reason="namespace adapted; read-only trace instrumentation added";end
    fprintf(fid,'| `reference/iter11/source_snapshot/+zhou/%s` | `%s` | adapted | %s |\n', ...
        rel,ref_target,ref_reason);
    ipm_reason="namespace adapted; inherited Case/frame/duration/vector logic";
    if rel=="+model/pmsm_derivative.m",ipm_reason="adapted to explicit Ld/Lq IPMSM equations with exact P0 branch";end
    if rel=="+model/electromagnetic_torque.m",ipm_reason="adapted to PM plus reluctance torque";end
    if rel=="+model/integrate_command.m",ipm_reason="adapted with configurable RK4 substep; dwell boundaries unchanged";end
    if rel=="+sim/run_closed_loop.m",ipm_reason="adapted plant/alpha/estimator state and audit logging; controller geometry frozen";end
    if rel=="+controller/icf_mpc_step.m",ipm_reason="F override hook for comparison only; default algebraic path frozen";end
    fprintf(fid,'| `reference/iter11/source_snapshot/+zhou/%s` | `%s` | adapted | %s |\n', ...
        rel,ipm_target,ipm_reason);
end
extra={ ...
    'external_iter11/config/paper_parameters.m','reference/iter11/config_snapshot/paper_parameters.m','unchanged','byte-for-byte frozen source'; ...
    'external_iter11/config/implementation_assumptions.m','reference/iter11/config_snapshot/implementation_assumptions.m','unchanged','byte-for-byte frozen source'; ...
    'external_iter11/config/experiment_definitions.m','reference/iter11/config_snapshot/experiment_definitions.m','unchanged','byte-for-byte frozen source'; ...
    'external_iter11/config/frame_alignment_config.m','reference/iter11/config_snapshot/frame_alignment_config.m','unchanged','byte-for-byte frozen source; not trusted as an active old entry'; ...
    'external_probe/model/ipmsm_dq_dynamics.m','src/+zhou_ipmsm/+model/pmsm_derivative.m','adapted','equation reference only; Iteration 11 queue/core retained'; ...
    'external_residual_audit/F_oracle_comparison.csv','reference/frozen_targets/F_oracle_comparison.csv','unchanged','read-only evidence; never read by runtime'; ...
    'old results/plots/logs/run_id','none','excluded','runtime dependency prohibited'};
for k=1:size(extra,1)
    fprintf(fid,'| `%s` | `%s` | %s | %s |\n',extra{k,1},extra{k,2},extra{k,3},extra{k,4});
end
end
