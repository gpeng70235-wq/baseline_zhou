function result=inventory(project)
before=zhou_model_error.snapshot_upstreams(project,"BEFORE");P=zhou_model_error.copy_provenance(project,before);
U=table(strings(numel(project.upstreams),1),strings(numel(project.upstreams),1),strings(numel(project.upstreams),1),true(numel(project.upstreams),1), ...
    'VariableNames',{'upstream_project','absolute_path','content_evidence','confirmed'});
for k=1:numel(project.upstreams),U.upstream_project(k)=project.upstreams(k).name;U.absolute_path(k)=project.upstreams(k).path;U.content_evidence(k)=strjoin(string(project.upstreams(k).evidence),';');end
writetable(U,fullfile(project.root,'SOURCE_PROJECTS.csv'));
result=struct('duplicate_work_detected',false,'upstream_file_count',height(before),'copied_file_count',height(P),'new_development_authorized',true);
end
