function h = sha256_file(path)
%SHA256_FILE Streaming SHA-256 with a fixed lowercase representation.
md = java.security.MessageDigest.getInstance('SHA-256');
fid = fopen(path, 'rb');
assert(fid >= 0, 'Cannot open for hashing: %s', path);
cleanup = onCleanup(@() fclose(fid));
while true
    bytes = fread(fid, 1024*1024, '*uint8');
    if isempty(bytes), break; end
    md.update(bytes);
end
d = typecast(md.digest(), 'uint8');
h = lower(string(reshape(dec2hex(d, 2).', 1, [])));
end
