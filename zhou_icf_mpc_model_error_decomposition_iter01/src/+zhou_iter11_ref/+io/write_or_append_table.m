function write_or_append_table(pathname, data)
%WRITE_OR_APPEND_TABLE Create a CSV or append rows with the same schema.

parent = fileparts(pathname);
if ~isempty(parent) && ~isfolder(parent)
    mkdir(parent);
end

if isfile(pathname)
    [fid,message]=fopen(pathname,'r');
    assert(fid>=0,'ZhouIter11Ref:FileOpenFailed','%s',message);
    cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
    header=string(strsplit(fgetl(fid),','));
    header=erase(header,'"');
    expected=string(data.Properties.VariableNames);
    assert(isequal(header,expected), ...
        'ZhouIter11Ref:CsvSchemaMismatch', 'CSV schema mismatch for %s', pathname);
    writetable(data, pathname, 'WriteMode', 'append', 'WriteVariableNames', false);
else
    writetable(data, pathname);
end
end
