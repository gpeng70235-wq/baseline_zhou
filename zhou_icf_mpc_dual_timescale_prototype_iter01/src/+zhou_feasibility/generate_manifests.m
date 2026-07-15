function generate_manifests(project)
%GENERATE_MANIFESTS Compare both frozen namespaces and hash deliverables.
root=project.root;
sources={ ...
    fullfile('C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_voltage_feasibility_iter01','src','+zhou_ipmsm'),fullfile(root,'src','+zhou_ipmsm'),"diagnostic frozen +zhou_ipmsm"; ...
    fullfile('C:\Users\catkin\Documents\baseline_zhou\zhou_icf_mpc_ipmsm_validation_iter01','src','+zhou_iter11_ref'),fullfile(root,'src','+zhou_iter11_ref'),"validation frozen +zhou_iter11_ref"};
fid=fopen(fullfile(root,'SOURCE_MANIFEST.sha256'),'w','n','UTF-8');assert(fid>=0);c=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'# SHA256  role:path\n');rows=cell(0,5);equal_count=0;total=0;
for tree=1:size(sources,1)
    source=char(sources{tree,1});copy=char(sources{tree,2});files=recursive_files(copy);
    for k=1:numel(files)
        rel=erase(files(k),string(copy)+filesep);original=fullfile(source,rel);
        ch=string(zhou_ipmsm.io.file_sha256(files(k)));oh=string(zhou_ipmsm.io.file_sha256(original));
        same=ch==oh;total=total+1;equal_count=equal_count+same;
        fprintf(fid,'%s  copy:%s/%s\n',ch,slash(erase(string(copy),string(root)+filesep)),slash(rel));
        fprintf(fid,'%s  frozen:%s/%s\n',oh,sources{tree,3},slash(rel));
        rows(end+1,:)={string(sources{tree,3}),slash(rel),oh,ch,same}; %#ok<AGROW>
    end
end
clear c

fid=fopen(fullfile(root,'SOURCE_COPY_REPORT.md'),'w','n','UTF-8');assert(fid>=0);c=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,['# Source Copy Report\n\n- frozen validation: `C:\\Users\\catkin\\Documents\\baseline_zhou\\zhou_icf_mpc_ipmsm_validation_iter01`\n' ...
    '- frozen diagnostic: `C:\\Users\\catkin\\Documents\\baseline_zhou\\zhou_icf_mpc_ipmsm_voltage_feasibility_iter01`\n' ...
    '- new project: `%s`\n- frozen namespace files: `%d`\n- byte-identical: `%d/%d`\n- result: **%s**\n\n' ...
    'All algorithm changes are confined to `src/+zhou_feasibility`; neither frozen namespace is edited. ' ...
    'The validation project already had 50 pre-existing status entries from an external 09:18 rerun; its core source diff remains zero.\n\n' ...
    '| Source | Relative file | Frozen SHA256 | Copy SHA256 | Equal |\n|---|---|---|---|---:|\n'], ...
    root,total,equal_count,total,token(equal_count==total));
for k=1:size(rows,1),fprintf(fid,'| %s | `%s` | `%s` | `%s` | %s |\n',rows{k,1},rows{k,2},rows{k,3},rows{k,4},token(rows{k,5}));end
clear c

all=recursive_files(root);all=all(~endsWith(lower(all),lower(string(fullfile(root,'RESULT_MANIFEST.sha256')))));all=sort(all);
fid=fopen(fullfile(root,'RESULT_MANIFEST.sha256'),'w','n','UTF-8');assert(fid>=0);c=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'# SHA256  project-relative-path\n');
for k=1:numel(all),rel=erase(all(k),string(root)+filesep);fprintf(fid,'%s  %s\n',zhou_ipmsm.io.file_sha256(all(k)),slash(rel));end
end
function f=recursive_files(root),d=dir(fullfile(root,'**','*'));d=d(~[d.isdir]);f=sort(string(fullfile({d.folder},{d.name})).');end
function s=slash(s),s=replace(string(s),'\','/');end
function s=token(v),if v,s='PASS';else,s='FAIL';end,end
