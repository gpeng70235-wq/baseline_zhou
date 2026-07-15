function result=prototype_gate(project,requested)
%PROTOTYPE_GATE This attribution project never implements a controller.
allowed=false;reason="Attribution-only scope: no ESO/RLS/identifier/higher-order controller is authorized.";
if requested
    status="BLOCKED_BY_SCOPE";
else
    status="DISABLED_BY_DEFAULT";
end
fid=fopen(fullfile(project.dirs.docs,'PROTOTYPE_GATE_REPORT.md'),'w');assert(fid>0);
cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'# Prototype Gate Report\n\n');
fprintf(fid,'Status: **%s**  \nPrototype allowed: **false**\n\n%s\n\n',status,reason);
fprintf(fid,'The `prototype` entry mode records this gate only. It does not create, tune, or run a new controller. The A–F conclusion may recommend a separate future project, but cannot authorize implementation here.\n');
result=struct('requested',logical(requested),'allowed',allowed,'status',status,'reason',reason);
end
