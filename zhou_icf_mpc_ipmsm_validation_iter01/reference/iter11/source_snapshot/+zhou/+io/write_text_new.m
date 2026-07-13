function write_text_new(pathname, content)
%WRITE_TEXT_NEW Write a new UTF-8 file and refuse to overwrite.

assert(~isfile(pathname), 'Zhou:NoOverwrite', ...
    'Refusing to overwrite existing file: %s', pathname);
[fid, message] = fopen(pathname, 'w', 'n', 'UTF-8');
assert(fid >= 0, 'Zhou:FileOpenFailed', '%s', message);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', char(content));
end

