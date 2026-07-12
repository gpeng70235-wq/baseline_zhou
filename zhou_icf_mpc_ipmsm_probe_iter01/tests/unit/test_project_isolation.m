function tests = test_project_isolation
tests = functiontests(localfunctions);
end

function testOnlyCurrentWorkspaceProjectIsVisible(test_case)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
entries = split(lower(string(path())),pathsep);
workspace_root = lower(string(fileparts(root)));
project_root = lower(string(root));
workspace_entry = startsWith(entries,workspace_root+filesep);
verifyFalse(test_case,any(workspace_entry & ~startsWith(entries,project_root)));
configured_user_path = lower(strtrim(string(userpath)));
if strlength(configured_user_path)>0
    verifyFalse(test_case,any(entries==configured_user_path));
end
for token = ["reproduction_iter10" "reproduction_iter11" ...
        "residual_daxis_audit" "zhou_icf_mpc_reproduction" "wu_"]
    verifyFalse(test_case,any(contains(entries,token)));
end
resolved = string({which('base_parameters'),which('ipmsm_parameters'), ...
    which('zhou_ipmsm.controller.icf_mpc_step')});
verifyTrue(test_case,all(startsWith(lower(resolved),project_root)));
end
