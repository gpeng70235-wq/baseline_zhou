function write_result_table(new_rows, path, append)
%WRITE_RESULT_TABLE Append safely, evolving a summary schema without row loss.
if nargin < 3
    append = false;
end
parent = fileparts(path);
if ~isfolder(parent)
    mkdir(parent);
end
if ~append || ~isfile(path)
    writetable(new_rows,path);
    return;
end

old_rows = readtable(path,'TextType','string','VariableNamingRule','preserve');
old_names = old_rows.Properties.VariableNames;
new_names = new_rows.Properties.VariableNames;
all_names = [old_names setdiff(new_names,old_names,'stable')];
for index = 1:numel(all_names)
    name = all_names{index};
    if ~ismember(name,old_names)
        old_rows.(name) = missing_column_like(new_rows.(name),height(old_rows));
    end
    if ~ismember(name,new_names)
        new_rows.(name) = missing_column_like(old_rows.(name),height(new_rows));
    end
end
old_rows = old_rows(:,all_names);
new_rows = new_rows(:,all_names);

% readtable may infer legacy text differently; normalize corresponding types.
text_columns = {'run_id','experiment_name','parameter_set','motor_type', ...
    'alpha_mode','timestamp'};
for index = 1:numel(all_names)
    name = all_names{index};
    old_value = old_rows.(name);
    new_value = new_rows.(name);
    if ismember(name,text_columns) || is_text_like(old_value) || is_text_like(new_value)
        old_rows.(name) = string(old_value);
        new_rows.(name) = string(new_value);
    elseif (isnumeric(old_value) || islogical(old_value)) && ...
            (isnumeric(new_value) || islogical(new_value))
        old_rows.(name) = double(old_value);
        new_rows.(name) = double(new_value);
    end
end
writetable([old_rows;new_rows],path);
end

function values = missing_column_like(example,count)
if isstring(example)
    values = strings(count,size(example,2));
    values(:) = missing;
elseif islogical(example)
    values = NaN(count,size(example,2));
elseif isnumeric(example)
    values = NaN(count,size(example,2),'like',example);
else
    values = repmat(missing,count,size(example,2));
end
end

function yes = is_text_like(value)
yes = isstring(value) || ischar(value) || iscellstr(value) || ...
    iscategorical(value) || isdatetime(value);
end
