function tests = test_no_external_runtime_dependency
tests = functiontests(localfunctions);
end

function testOnlineCodeContainsNoLegacyAbsoluteDependency(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
folders={fullfile(root,'src'),fullfile(root,'config'), ...
    fullfile(root,'experiments'),fullfile(root,'estimators')};
forbidden=["c:\\users\\catkin", ...
    "zhou_icf_mpc_reproduction_iter10", ...
    "zhou_icf_mpc_reproduction_iter11", ...
    "zhou_iter11_residual_daxis_audit_iter01", ...
    "zhou_icf_mpc_ipmsm_probe_iter01"];
for folder=folders
    if ~isfolder(folder{1}), continue; end
    files=dir(fullfile(folder{1},'**','*.m'));
    for k=1:numel(files)
        content=lower(string(fileread(fullfile(files(k).folder,files(k).name))));
        for token=forbidden
            verifyFalse(testCase,contains(content,token), ...
                "Legacy runtime dependency in "+fullfile(files(k).folder,files(k).name));
        end
    end
end
end

function testCriticalRuntimeSymbolsResolveLocally(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
symbols=["zhou_iter11_ref.controller.icf_mpc_step", ...
    "zhou_iter11_ref.sim.run_closed_loop", ...
    "zhou_ipmsm.controller.icf_mpc_step", ...
    "zhou_ipmsm.sim.run_closed_loop", ...
    "zhou_validation.compare_pointwise_runs"];
for symbol=symbols
    resolved=string(which(symbol));
    verifyGreaterThan(testCase,strlength(resolved),0,"Unresolved runtime symbol: "+symbol);
    verifyTrue(testCase,startsWith(lower(resolved),lower(string(root))+filesep), ...
        "Runtime symbol escaped project: "+symbol+" -> "+resolved);
end
end
