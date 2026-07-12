function manifest_hash = generate_source_manifest(root)
%GENERATE_SOURCE_MANIFEST Binary-safe, deterministic source SHA-256 manifest.
output = fullfile(root,'SOURCE_MANIFEST.sha256');
files = dir(fullfile(root,'**','*'));
files = files(~[files.isdir]);
relative = strings(0,1);
absolute = strings(0,1);
excluded_roots = ["results" "plots" "diagnostics" "logs"];
for index = 1:numel(files)
    path = fullfile(files(index).folder,files(index).name);
    rel = erase(string(path),string(root)+filesep);
    first_part = extractBefore(rel+filesep,filesep);
    if path==string(output) || ismember(first_part,excluded_roots)
        continue;
    end
    relative(end+1,1) = replace(rel,filesep,"/"); %#ok<AGROW>
    absolute(end+1,1) = string(path); %#ok<AGROW>
end
[relative,order] = sort(relative);
absolute = absolute(order);

fid = fopen(output,'w');
assert(fid>=0,'ZhouIPMSM:ManifestOpen','Cannot open source manifest for writing.');
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
for index = 1:numel(relative)
    fprintf(fid,'%s  %s\n',sha256_file(absolute(index)),relative(index));
end
clear cleanup;
manifest_hash = sha256_file(output);
end

function hash = sha256_file(path)
digest = java.security.MessageDigest.getInstance('SHA-256');
[fid,message] = fopen(path,'r');
assert(fid>=0,'ZhouIPMSM:FileOpen','%s',message);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
while ~feof(fid)
    block = fread(fid,1024*1024,'*uint8');
    if ~isempty(block)
        digest.update(block);
    end
end
bytes = typecast(digest.digest(),'uint8');
hash = lower(string(reshape(dec2hex(bytes,2).',1,[])));
end
