function hash = file_sha256(pathname)
%FILE_SHA256 SHA-256 for immutable run provenance.

md = java.security.MessageDigest.getInstance('SHA-256');
[fid,message]=fopen(pathname,'r');
assert(fid>=0,'ZhouIPMSM:FileOpenFailed','%s',message);
cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
while ~feof(fid)
    block=fread(fid,1024*1024,'*uint8');
    if ~isempty(block)
        md.update(block);
    end
end
digest=typecast(md.digest(),'uint8');
hash=lower(string(reshape(dec2hex(digest,2).',1,[])));
end

