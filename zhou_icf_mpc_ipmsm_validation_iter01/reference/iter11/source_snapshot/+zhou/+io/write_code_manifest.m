function aggregate_hash = write_code_manifest(project_root, destination_csv)
%WRITE_CODE_MANIFEST Hash source/config/docs used by a run.

patterns={'*.m','*.md','*.txt'};
files=[];
for k=1:numel(patterns)
    files=[files;dir(fullfile(project_root,'**',patterns{k}))]; %#ok<AGROW>
end
keep=true(numel(files),1);
for k=1:numel(files)
    full=fullfile(files(k).folder,files(k).name);
    rel=erase(string(full),string(project_root)+filesep);
    keep(k)=~startsWith(rel,"results"+filesep) && ...
        ~startsWith(rel,"plots"+filesep) && ...
        ~startsWith(rel,"diagnostics"+filesep);
end
files=files(keep);
relative_path=strings(numel(files),1);
bytes=zeros(numel(files),1);
sha256=strings(numel(files),1);
for k=1:numel(files)
    full=fullfile(files(k).folder,files(k).name);
    relative_path(k)=erase(string(full),string(project_root)+filesep);
    bytes(k)=files(k).bytes;
    sha256(k)=zhou.io.file_sha256(full);
end
[relative_path,order]=sort(relative_path);
bytes=bytes(order); sha256=sha256(order);
manifest=table(relative_path,bytes,sha256);
writetable(manifest,destination_csv);

md=java.security.MessageDigest.getInstance('SHA-256');
for k=1:height(manifest)
    md.update(uint8(char(manifest.relative_path(k)+"|"+manifest.sha256(k)+newline)));
end
digest=typecast(md.digest(),'uint8');
aggregate_hash=lower(string(reshape(dec2hex(digest,2).',1,[])));
end

