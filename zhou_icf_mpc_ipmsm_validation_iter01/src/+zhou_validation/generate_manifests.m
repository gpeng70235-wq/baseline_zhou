function generate_manifests(project)
%GENERATE_MANIFESTS Write stable source hashes and complete delivery inventory.

files=dir(fullfile(project.root,'**','*'));files=files(~[files.isdir]);
relative=strings(numel(files),1);size_bytes=zeros(numel(files),1);sha=strings(numel(files),1);
included=true(numel(files),1);reason=strings(numel(files),1);
for k=1:numel(files)
    full=fullfile(files(k).folder,files(k).name);
    relative(k)=replace(erase(string(full),string(project.root)+filesep),filesep,'/');
    size_bytes(k)=files(k).bytes;
    if excluded_name(relative(k))
        included(k)=false;reason(k)="cache_or_temporary_file";
    elseif size_bytes(k)>50*1024^2
        included(k)=false;reason(k)=">50_MB_not_committed";
    end
    sha(k)=file_sha256(full);
end
keep=relative~="delivery/repo_file_manifest.csv";
relative=relative(keep);size_bytes=size_bytes(keep);sha=sha(keep);
included=included(keep);reason=reason(keep);
[relative,order]=sort(relative);size_bytes=size_bytes(order);sha=sha(order);
included=included(order);reason=reason(order);
manifest=table(relative,size_bytes,sha,included,reason, ...
    'VariableNames',{'relative_path','size_bytes','sha256','included','exclusion_reason'});
writetable(manifest,fullfile(project.root,'delivery','repo_file_manifest.csv'));
writetable(manifest(~manifest.included,:),fullfile(project.root,'delivery','excluded_large_files.csv'));

source=manifest(manifest.included & (endsWith(manifest.relative_path,'.m') | ...
    startsWith(manifest.relative_path,'reference/') | startsWith(manifest.relative_path,'docs/')),:);
source=source(~contains(source.relative_path,'SOURCE_MANIFEST'),:);
fid=fopen(fullfile(project.root,'SOURCE_MANIFEST.sha256'),'w','n','UTF-8');assert(fid>=0);
cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
for k=1:height(source),fprintf(fid,'%s  %s\n',source.sha256(k),source.relative_path(k));end
end

function tf=excluded_name(path_value)
lower_path=lower(path_value);
tf=endsWith(lower_path,'.asv') || endsWith(lower_path,'~') || ...
    contains(lower_path,'slprj/') || contains(lower_path,'.git/') || ...
    endsWith(lower_path,'.autosave') || contains(lower_path,'/temp/');
end
function value=file_sha256(path_value)
md=java.security.MessageDigest.getInstance('SHA-256');
fid=fopen(path_value,'r');assert(fid>=0);cleanup=onCleanup(@() fclose(fid));
while ~feof(fid)
    block=fread(fid,1024*1024,'*uint8');
    if ~isempty(block),md.update(block);end
end
bytes=typecast(md.digest(),'uint8');value=lower(string(reshape(dec2hex(bytes,2).',1,[])));
end
