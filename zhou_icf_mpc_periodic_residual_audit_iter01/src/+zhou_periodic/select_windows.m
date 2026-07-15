function [W, split] = select_windows(cfg, T)
%SELECT_WINDOWS Preregistered, non-visual steady-window and cycle selection.
fprintf('Phase 2: selecting steady windows without peak-based screening...\n');
ids = unique(T.case_id,'stable');
rows = repmat(empty_window(),numel(ids),1);
splitRows = repmat(empty_split(),0,1);
nominalComplete = max(groupcounts(T.case_id));

for k = 1:numel(ids)
    c = T(T.case_id==ids(k),:);
    r = empty_window(); r.case_id = ids(k); r.window_id = ids(k)+"__steady";
    r.category = c.category(1); r.range_class = c.range_class(1);
    r.case_sample_count = height(c); r.complete_termination = height(c)==nominalComplete;
    r.mean_speed = mean(c.speed_rpm,'omitnan');
    r.speed_variation = std(c.speed_rpm,'omitnan')/max(abs(r.mean_speed),eps);
    r.mean_electrical_frequency_hz = mean(abs(c.electrical_speed),'omitnan')/(2*pi);
    r.sample_rate_hz = cfg.fs_Hz;
    r.nyquist_frequency_hz = cfg.fs_Hz/2;
    r.nyquist_order = r.nyquist_frequency_hz/max(r.mean_electrical_frequency_hz,eps);
    if r.category=="dynamic"
        r.evidence_role = "SECONDARY_DYNAMIC";
    elseif r.range_class=="stress_test"
        r.evidence_role = "SECONDARY_STRESS";
    else
        r.evidence_role = "ENGINEERING_PRIMARY";
    end

    steady = find(c.phase=="steady");
    reason = strings(0,1);
    if isempty(steady)
        r.start_sample = c.sample_index(1); r.end_sample = c.sample_index(end);
        reason(end+1) = "no_registered_steady_phase"; %#ok<AGROW>
    else
        fe = r.mean_electrical_frequency_hz;
        samplesPerCycle = cfg.fs_Hz/max(fe,eps);
        nCycles = floor(numel(steady)/samplesPerCycle + 1e-10);
        nUse = round(nCycles*samplesPerCycle);
        nUse = min(nUse,numel(steady));
        use = steady(1:max(1,nUse));
        r.start_sample = c.sample_index(use(1)); r.end_sample = c.sample_index(use(end));
        r.start_time_s = c.time_s(use(1)); r.end_time_s = c.time_s(use(end));
        r.electrical_cycles = nCycles;
        r.window_sample_count = numel(use);
        if nCycles < cfg.minimum_cycles, reason(end+1)="fewer_than_3_complete_cycles"; end %#ok<AGROW>
        if nCycles >= cfg.minimum_cycles
            nCal = floor(nCycles/2); nVal = nCycles-nCal;
            theta0 = c.electrical_angle(use(1));
            for q = 1:nCycles
                sr = empty_split(); sr.case_id=ids(k); sr.window_id=r.window_id; sr.cycle_id=q;
                sr.theta_start=theta0+(q-1)*2*pi; sr.theta_end=theta0+q*2*pi;
                cmask=c.electrical_angle>=sr.theta_start & c.electrical_angle<sr.theta_end & ...
                    c.sample_index>=r.start_sample & c.sample_index<=r.end_sample;
                ci=find(cmask);
                if isempty(ci)
                    sr.start_sample=NaN;sr.end_sample=NaN;sr.sample_count=0;
                else
                    sr.start_sample=c.sample_index(ci(1));sr.end_sample=c.sample_index(ci(end));sr.sample_count=numel(ci);
                end
                if q<=nCal, sr.split="calibration"; else, sr.split="validation"; end
                sr.calibration_cycle_count=nCal;sr.validation_cycle_count=nVal;
                sr.evidence_role=r.evidence_role;
                splitRows(end+1,1)=sr; %#ok<AGROW>
            end
        end
    end
    if ~r.complete_termination, reason(end+1)="early_termination"; end %#ok<AGROW>
    if r.range_class=="stress_test", reason(end+1)="stress_test_secondary_only"; end %#ok<AGROW>
    if r.speed_variation>cfg.maximum_speed_cv, reason(end+1)="speed_variation_exceeds_1pct"; end %#ok<AGROW>
    if r.mean_electrical_frequency_hz<=eps, reason(end+1)="electrical_frequency_near_zero"; end %#ok<AGROW>
    if r.nyquist_order<max(cfg.display_orders), reason(end+1)="aliasing_through_order_20"; end %#ok<AGROW>
    r.valid_for_order_tracking = r.complete_termination && r.range_class~="stress_test" && ...
        r.electrical_cycles>=cfg.minimum_cycles && r.mean_electrical_frequency_hz>eps;
    r.valid_for_fft = r.valid_for_order_tracking && r.speed_variation<=cfg.maximum_speed_cv && ...
        r.nyquist_order>=max(cfg.display_orders);
    if isempty(reason), r.exclusion_reason=""; else, r.exclusion_reason=strjoin(reason,";"); end
    rows(k)=r;
end

W = struct2table(rows,'AsArray',true);
if isempty(splitRows), split=struct2table(empty_split(),'AsArray',true); split(1,:)=[];
else, split=struct2table(splitRows,'AsArray',true); end
zhou_periodic.write_table(W,fullfile(cfg.summary_dir,'window_registry.csv'));
zhou_periodic.write_table(split,fullfile(cfg.summary_dir,'train_validation_split.csv'));
write_protocol(cfg,W,split);
end

function r=empty_window()
r=struct('case_id',"",'window_id',"",'category',"",'range_class',"", ...
    'evidence_role',"",'case_sample_count',0,'complete_termination',false, ...
    'start_sample',NaN,'end_sample',NaN,'start_time_s',NaN,'end_time_s',NaN, ...
    'window_sample_count',0,'electrical_cycles',0,'mean_speed',NaN, ...
    'speed_variation',NaN,'mean_electrical_frequency_hz',NaN,'sample_rate_hz',NaN, ...
    'nyquist_frequency_hz',NaN,'nyquist_order',NaN,'valid_for_fft',false, ...
    'valid_for_order_tracking',false,'exclusion_reason',"");
end
function r=empty_split()
r=struct('case_id',"",'window_id',"",'cycle_id',0,'start_sample',NaN, ...
    'end_sample',NaN,'sample_count',0,'theta_start',NaN,'theta_end',NaN, ...
    'split',"",'calibration_cycle_count',0,'validation_cycle_count',0, ...
    'evidence_role',"");
end
function write_protocol(cfg,W,S)
valid=W(W.valid_for_order_tracking,:); primary=valid(valid.evidence_role=="ENGINEERING_PRIMARY",:);
L=["# Window Selection Protocol";""; ...
    "Selection is deterministic and uses registered phase labels, termination status, electrical speed, and complete-cycle counts. No residual amplitude or visible peak enters selection.";""; ...
    "## Rules";""; ...
    "1. Start at the first upstream-registered `steady` sample."; ...
    "2. Keep the largest integer number of electrical cycles from that point."; ...
    "3. Require at least "+cfg.minimum_cycles+" cycles, complete 1198-row termination, non-stress range, nonzero electrical frequency, and Nyquist support through order 20."; ...
    "4. Require speed CV <= "+sprintf('%.2f%%',100*cfg.maximum_speed_cv)+" for time FFT."; ...
    "5. Core and parameter cases are ENGINEERING_PRIMARY. Dynamic cases are retained only as SECONDARY_DYNAMIC; stress and early termination evidence cannot lead the conclusion."; ...
    "6. Complete cycles are split in time order: floor(N/2) calibration cycles and the remaining cycles held out for validation.";""; ...
    "## Outcome";""; ...
    "- Valid order-tracking windows: **"+height(valid)+"**."; ...
    "- Valid ENGINEERING_PRIMARY windows: **"+height(primary)+"**."; ...
    "- Valid complete electrical cycles: **"+sum(valid.electrical_cycles)+"** (primary: **"+sum(primary.electrical_cycles)+"**)."; ...
    "- Calibration/validation cycles: **"+nnz(S.split=="calibration")+" / "+nnz(S.split=="validation")+"**.";""; ...
    "Every excluded case and reason is retained in `results/summary/window_registry.csv`."];
writelines(L,fullfile(cfg.docs_dir,'WINDOW_SELECTION_PROTOCOL.md'),'Encoding','UTF-8');
end
