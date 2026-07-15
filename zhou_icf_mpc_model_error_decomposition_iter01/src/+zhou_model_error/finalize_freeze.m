function result=finalize_freeze(project)
after=zhou_model_error.snapshot_upstreams(project,"AFTER");before=readtable(fullfile(project.root,'SOURCE_SHA256_BEFORE.csv'),'TextType','string');
kb=before.upstream_project+"|"+before.relative_path;ka=after.upstream_project+"|"+after.relative_path;keys=unique([kb;ka]);status=strings(numel(keys),1);hb=strings(numel(keys),1);ha=hb;
for k=1:numel(keys),ib=find(kb==keys(k),1);ia=find(ka==keys(k),1);if isempty(ib),status(k)="added";ha(k)=after.sha256(ia);elseif isempty(ia),status(k)="deleted";hb(k)=before.sha256(ib);else,hb(k)=before.sha256(ib);ha(k)=after.sha256(ia);if hb(k)==ha(k),status(k)="unchanged";else,status(k)="modified";end,end,end
V=table(keys,hb,ha,status,'VariableNames',{'file_key','sha256_before','sha256_after','status'});writetable(V,fullfile(project.root,'FROZEN_UPSTREAM_VALIDATION.csv'));changed=nnz(status~="unchanged");
P=readtable(fullfile(project.root,'COPIED_FILE_PROVENANCE.csv'),'TextType','string');ok=true(height(P),1);for k=1:height(P),ok(k)=isfile(P.destination_absolute_path(k))&&zhou_ipmsm.io.file_sha256(P.destination_absolute_path(k))==P.sha256(k);end
assert(changed==0,'ZhouModelError:UpstreamMutation');assert(all(ok),'ZhouModelError:LocalCopyMutation');
result=struct('upstream_changed_files',changed,'upstream_files',height(after),'copied_files_verified',height(P),'copied_files_failed',nnz(~ok));
end
