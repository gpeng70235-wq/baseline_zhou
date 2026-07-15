function T=snapshot_upstreams(project,label)
arguments,project struct,label (1,1) string {mustBeMember(label,["BEFORE","AFTER"])}="BEFORE",end
rows=cell(0,6);
for u=1:numel(project.upstreams)
    root=project.upstreams(u).path;files=dir(fullfile(root,'**','*'));files=files(~[files.isdir]);
    for k=1:numel(files)
        absolute=fullfile(files(k).folder,files(k).name);hash="";last="";
        for attempt=1:10,try,hash=zhou_ipmsm.io.file_sha256(absolute);break,catch ME,last=string(ME.message);pause(.2);end,end
        assert(strlength(hash)>0,'ZhouModelError:HashReadFailure','%s: %s',absolute,last);
        rows(end+1,:)={project.upstreams(u).name,string(root),erase(string(absolute),string(root)+filesep),files(k).bytes, ...
            string(datetime(files(k).datenum,'ConvertFrom','datenum','Format','yyyy-MM-dd''T''HH:mm:ss.SSS')),hash}; %#ok<AGROW>
    end
end
T=cell2table(rows,'VariableNames',{'upstream_project','upstream_root','relative_path','size_bytes','last_write_time','sha256'});
T=sortrows(T,{'upstream_project','relative_path'});writetable(T,fullfile(project.root,"SOURCE_SHA256_"+label+".csv"));
end
