function P=copy_provenance(project,before)
folders={fullfile(project.root,'src'),fullfile(project.root,'config'),fullfile(project.root,'reference','upstream_snapshots')};dest=[];
for f=1:numel(folders),x=dir(fullfile(folders{f},'**','*'));dest=[dest;x(~[x.isdir])];end %#ok<AGROW>
rows=cell(0,11);
for k=1:numel(dest)
    dpath=fullfile(dest(k).folder,dest(k).name);dh=zhou_ipmsm.io.file_sha256(dpath);match=find(before.sha256==dh&before.size_bytes==dest(k).bytes);
    if isempty(match),continue,end
    rel=erase(string(dpath),string(project.root)+filesep);preferred="sequence_decomposition";
    if contains(rel,"ipmsm_probe"),preferred="ipmsm_probe";end
    if contains(rel,"s2_feasibility"),preferred="s2_feasibility";end
    if contains(rel,"robust_residual"),preferred="robust_residual";end
    if contains(rel,"jd_jq_audit"),preferred="jd_jq_audit";end
    choice=match(find(before.upstream_project(match)==preferred,1));if isempty(choice),choice=match(1);end
    source=fullfile(before.upstream_root(choice),before.relative_path(choice));use="frozen evidence snapshot";
    if startsWith(rel,'src'),use="runtime frozen controller/plant/S2 closure";elseif startsWith(rel,'config'),use="runtime frozen configuration";end
    rows(end+1,:)={before.upstream_project(choice),string(source),before.relative_path(choice),dest(k).bytes, ...
        string(datetime(dest(k).datenum,'ConvertFrom','datenum','Format','yyyy-MM-dd''T''HH:mm:ss.SSS')),dh,true,true,string(dpath),rel,use}; %#ok<AGROW>
end
P=cell2table(rows,'VariableNames',{'upstream_project','source_absolute_path','source_relative_path','file_size_bytes','modified_time','sha256','copied_to_new_project','byte_identical','destination_absolute_path','destination_relative_path','use_in_new_project'});
P=sortrows(P,{'upstream_project','source_relative_path'});writetable(P,fullfile(project.root,'COPIED_FILE_PROVENANCE.csv'));
assert(all(P.byte_identical),'ZhouModelError:CopyMismatch');
end
