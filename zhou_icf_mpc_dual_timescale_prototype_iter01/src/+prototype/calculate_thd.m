function [thd,valid,cycles] = calculate_thd(phase,time_s,electrical_hz)
%CALCULATE_THD Integer-cycle wrapper; invalid fundamentals stay explicitly invalid.
thd=NaN;valid=false;cycles=0;
if electrical_hz<=0||numel(phase)<4,return;end
duration=time_s(end)-time_s(1);cycles=floor(duration*electrical_hz);
if cycles<3,return;end
start=time_s(end)-cycles/electrical_hz;mask=time_s>=start;
[candidate,~,~]=zhou_ipmsm.metrics.phase_thd_total_rms(phase(mask),time_s(mask),electrical_hz);
fundamental_rms=rms(phase(mask));
if isfinite(candidate)&&fundamental_rms>1e-6,thd=candidate;valid=true;end
end
