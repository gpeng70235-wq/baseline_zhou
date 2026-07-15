function outcome = run_dual_timescale_prototype(mode)
%RUN_DUAL_TIMESCALE_PROTOTYPE Isolated closed-loop prototype entry point.
if nargin<1 || strlength(string(mode))==0, mode="all"; else, mode=string(mode); end
setappdata(0,'dual_timescale_requested_mode',mode);
restoredefaultpath;
rehash toolboxcache;
clear classes;
clear functions;
clear mex;
close all;
clc;
mode=string(getappdata(0,'dual_timescale_requested_mode'));
rmappdata(0,'dual_timescale_requested_mode');
allowed=["inventory","wiring","baseline","smoke","calibration","minimal", ...
    "full","ablation","sensitivity","timing","audit","all"];
assert(isscalar(mode)&&ismember(mode,allowed),'Prototype:InvalidMode');
root=fileparts(mfilename('fullpath'));
addpath(root,fullfile(root,'config'),fullfile(root,'src'));
project=initialize_project();
outcome=struct('mode',mode,'root',string(root),'run_id',project.run_id);
switch mode
    case "inventory", outcome.inventory=prototype.inventory_audit(project,"before");
    case "wiring", outcome.wiring=prototype.wiring_gate(project);
    case "baseline", outcome.baseline=prototype.baseline_gate(project);
    case "smoke", outcome.smoke=prototype.smoke_test(project);
    case "calibration", outcome.calibration=prototype.calibration(project);
    case "minimal", outcome.minimal=prototype.run_minimal(project);
    case "full", outcome.full=prototype.run_full(project);
    case "ablation", outcome.ablation=prototype.run_ablation(project);
    case "sensitivity", outcome.sensitivity=prototype.run_sensitivity(project);
    case "timing", outcome.timing=prototype.run_timing(project);
    case "audit", outcome.audit=prototype.finalize_audit(project);
    otherwise
        outcome.inventory=prototype.inventory_audit(project,"before");
        outcome.wiring=prototype.wiring_gate(project); assert(outcome.wiring.pass,'Prototype:WiringGate');
        outcome.baseline=prototype.baseline_gate(project); assert(outcome.baseline.pass,'Prototype:BaselineGate');
        outcome.calibration=prototype.calibration(project); assert(outcome.calibration.pass,'Prototype:CalibrationGate');
        outcome.minimal=prototype.run_minimal(project);
        if outcome.minimal.pass
            outcome.full=prototype.run_full(project);
            outcome.ablation=prototype.run_ablation(project);
            outcome.sensitivity=prototype.run_sensitivity(project);
            outcome.timing=prototype.run_timing(project);
        else
            outcome.full=struct('status',"SKIPPED_MINIMAL_GATE");
            outcome.ablation=struct('status',"SKIPPED_MINIMAL_GATE");
            outcome.sensitivity=struct('status',"SKIPPED_MINIMAL_GATE");
            outcome.timing=struct('status',"SKIPPED_MINIMAL_GATE");
        end
        outcome.audit=prototype.finalize_audit(project);
end
save(fullfile(project.dirs.summary,'last_run_outcome.mat'),'outcome','-v7.3');
end
