function write_table(T, path)
%WRITE_TABLE Stable CSV writer used by every registered table.
parent = fileparts(path);
if ~isfolder(parent), mkdir(parent); end
writetable(T, path, 'Encoding', 'UTF-8');
end
