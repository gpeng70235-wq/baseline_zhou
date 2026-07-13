function tests = test_project_isolation
tests = functiontests(localfunctions);
end

function testOnlyCurrentProjectResolves(testCase)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
entries = split(lower(string(path)),pathsep);
forbidden = ["zhou_icf_mpc_reproduction_iter10", ...
    "zhou_icf_mpc_reproduction_iter11", ...
    "zhou_iter11_residual_daxis_audit_iter01", ...
    "zhou_icf_mpc_ipmsm_probe_iter01", "baseline_wu", "wu2025_pdvm"];
for token = forbidden
    verifyFalse(testCase,any(contains(entries,lower(token))), ...
        "Forbidden project is present on the MATLAB path: "+token);
end
symbols = ["base_parameters", "ipmsm_parameters", ...
    "zhou_iter11_ref.sim.run_closed_loop", ...
    "zhou_ipmsm.sim.run_closed_loop", ...
    "zhou_ipmsm.controller.icf_mpc_step"];
for symbol = symbols
    resolved = string(which(symbol));
    verifyNotEmpty(testCase,resolved,"Required symbol is unresolved: "+symbol);
    verifyTrue(testCase,is_inside(resolved,root), ...
        "Symbol escaped the current project: "+symbol+" -> "+resolved);
end
end

function yes = is_inside(path_value,root)
p = lower(string(path_value)); r = lower(string(root));
yes = p==r || startsWith(p,r+filesep);
end
