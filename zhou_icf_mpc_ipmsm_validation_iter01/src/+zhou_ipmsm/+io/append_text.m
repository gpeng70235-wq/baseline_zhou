function append_text(pathname, content)
%APPEND_TEXT Append UTF-8 text while preserving all historical content.

parent = fileparts(pathname);
if ~isempty(parent) && ~isfolder(parent)
    mkdir(parent);
end
[fid, message] = fopen(pathname, 'a', 'n', 'UTF-8');
assert(fid >= 0, 'ZhouIPMSM:FileOpenFailed', '%s', message);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', char(content));
end
