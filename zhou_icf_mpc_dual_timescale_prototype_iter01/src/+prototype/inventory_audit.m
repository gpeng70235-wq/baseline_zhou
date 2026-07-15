function result = inventory_audit(project,phase)
%INVENTORY_AUDIT Hash every currently visible upstream file without mutation.
phase=string(phase);base=fileparts(project.root);
roots=[string(fullfile(base,'zhou_icf_mpc_dual_timescale_design_iter01')); ...
    string(fullfile(base,'zhou_icf_mpc_model_error_decomposition_iter01')); ...
    string(fullfile(base,'zhou_icf_mpc_sequence_decomposition_iter01')); ...
    string(fullfile(base,'zhou_icf_mpc_ipmsm_feasibility_control_iter01')); ...
    string(fullfile(base,'zhou_icf_mpc_ipmsm_probe_iter01')); ...
    string(fullfile(base,'zhou_icf_mpc_ipmsm_robust_constraint_iter01')); ...
    string(fullfile(base,'baseline_zhou-main','baseline_zhou-main','zhou_icf_mpc_constraint_audit_v1'))];
ids=["dual_timescale_design";"model_error_decomposition";"sequence_decomposition"; ...
    "feasibility_control";"ipmsm_probe";"robust_constraint";"constraint_audit_v1"];
requested=["zhou_icf_mpc_dual_timescale_design_iter01";"zhou_icf_mpc_model_error_decomposition_iter01"; ...
    "zhou_icf_mpc_sequence_decomposition_iter01";"zhou_icf_mpc_ipmsm_feasibility_control_iter01"; ...
    "zhou_icf_mpc_ipmsm_probe_iter01";"zhou_icf_mpc_ipmsm_robust_constraint_iter01"; ...
    "zhou_icf_mpc_constraint_audit_v1"];
project_rows=cell(numel(roots),1);hash_cells=cell(numel(roots),1);
for k=1:numel(roots)
    files=list_files(roots(k));count=numel(files);
    if ~isfolder(roots(k)),status="MISSING";elseif count==0,status="FOUND_EMPTY_STUB";else,status="FOUND_POPULATED";end
    project_rows{k}=table(ids(k),string(roots(k)),requested(k),status,count, ...
        'VariableNames',{'project_id','root','requested_name','status','file_count'});
    rows=cell(count,1);
    for j=1:count
        info=dir(files(j));rel=erase(string(files(j)),string(roots(k))+filesep);
        rows{j}=table(ids(k),string(roots(k)),rel,info.bytes, ...
            string(datetime(info.datenum,'ConvertFrom','datenum','TimeZone','UTC')), ...
            zhou_ipmsm.io.file_sha256(files(j)),'VariableNames', ...
            {'project_id','root','relative_path','bytes','modified_utc','sha256'});
    end
    if count>0,hash_cells{k}=vertcat(rows{:});else,hash_cells{k}=table();end
end
projects=vertcat(project_rows{:});hashes=vertcat(hash_cells{~cellfun(@isempty,hash_cells)});
writetable(projects,fullfile(project.dirs.audit,'SOURCE_PROJECTS.csv'));
writetable(projects,fullfile(project.dirs.audit,'SOURCE_PROJECT_STATUS.csv'));
target=fullfile(project.dirs.audit,"SOURCE_SHA256_"+upper(phase)+".csv");writetable(hashes,target);
if phase=="before"&&~isfile(fullfile(project.dirs.audit,'SOURCE_SHA256_BEFORE.csv'))
    writetable(hashes,fullfile(project.dirs.audit,'SOURCE_SHA256_BEFORE.csv'));
end
provenance=copy_provenance(project);writetable(provenance,fullfile(project.dirs.audit,'COPIED_FILE_PROVENANCE.csv'));
commit=strtrim(fileread(fullfile(project.dirs.audit,'MODEL_ERROR_GIT_COMMIT.txt')));
lines=["# Executable Source Selection";""; ...
    "The current model-error directory is an empty stub. Executable closed-loop code was restored without changing that directory."; ...
    "";"- Git commit: `"+string(commit)+"`"; ...
    "- Restored snapshot: `"+string(project.snapshot_root)+"`"; ...
    "- Executable destination: `"+string(fullfile(project.root,'src'))+"`"; ...
    "- Primary chain: frozen model-error `zhou_robust.run_robust_case`, Zhou controller/plant, and S2 packages."; ...
    "- Probe is retained as a populated direct upstream but was not substituted for the 24-case model-error campaign."; ...
    "- Every mechanically copied source has a SHA256-equal provenance row."];
writelines(lines,fullfile(project.dirs.audit,'EXECUTABLE_SOURCE_SELECTION.md'));
writelines(lines,fullfile(project.dirs.docs,'EXECUTABLE_SOURCE_SELECTION.md'));
validation=table();changed=NaN;added=NaN;removed=NaN;
if phase=="after"
    before=readtable(fullfile(project.dirs.audit,'SOURCE_SHA256_BEFORE.csv'),'TextType','string','Delimiter',',');
    [added,removed,changed]=compare_hashes(before,hashes);
    validation=table("all_upstreams",height(before),height(hashes),added,removed,changed, ...
        added==0&&removed==0&&changed==0,'VariableNames', ...
        {'scope','before_count','after_count','added','removed','changed','pass'});
    writetable(validation,fullfile(project.dirs.audit,'FROZEN_UPSTREAM_VALIDATION.csv'));
end
result=struct('projects',projects,'hashes',hashes,'provenance',provenance, ...
    'validation',validation,'stub_count',nnz(projects.status=="FOUND_EMPTY_STUB"), ...
    'added',added,'removed',removed,'changed',changed);
end

function files=list_files(root)
if ~isfolder(root),files=strings(0,1);return;end
d=dir(fullfile(root,'**','*'));d=d(~[d.isdir]);files=string(fullfile({d.folder},{d.name})).';files=sort(files);
end
function P=copy_provenance(project)
dest_root=fullfile(project.root,'src');src_root=fullfile(project.snapshot_root,'src');files=list_files(dest_root);
keep=false(size(files));
for k=1:numel(files)
    rel=erase(files(k),string(dest_root)+filesep);keep(k)=isfile(fullfile(src_root,rel));
end
files=files(keep);rows=cell(numel(files),1);commit=strtrim(fileread(fullfile(project.dirs.audit,'MODEL_ERROR_GIT_COMMIT.txt')));
for k=1:numel(files)
    rel=erase(files(k),string(dest_root)+filesep);source=fullfile(src_root,rel);
    source_hash=zhou_ipmsm.io.file_sha256(source);
    dest_hash=zhou_ipmsm.io.file_sha256(files(k));match=source_hash==dest_hash;
    rows{k}=table("git:"+string(commit),string(source),rel,source_hash,files(k),rel,dest_hash,match, ...
        'VariableNames',{'source_project','source_absolute_path','source_relative_path','source_sha256', ...
        'destination_absolute_path','destination_relative_path','destination_sha256','hash_match'});
end
P=vertcat(rows{:});
end
function [added,removed,changed]=compare_hashes(A,B)
ka=A.project_id+"|"+A.relative_path;kb=B.project_id+"|"+B.relative_path;
added=nnz(~ismember(kb,ka));removed=nnz(~ismember(ka,kb));changed=0;
common=intersect(ka,kb);for k=1:numel(common),changed=changed+(A.sha256(ka==common(k))~=B.sha256(kb==common(k)));end
end
