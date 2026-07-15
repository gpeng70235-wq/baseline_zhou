function [thd_percent,harmonic_rms] = phase_thd(signal,time_s,fundamental_Hz,max_harmonic)
%PHASE_THD Least-squares harmonic projection for a known electrical frequency.
% This metric convention is an implementation assumption (A10).

x=signal(:)-mean(signal(:));
t=time_s(:);
nyquist=0.5/median(diff(t));
H=min(max_harmonic,floor(nyquist/fundamental_Hz));
harmonic_rms=zeros(H,1);
for h=1:H
    M=[cos(2*pi*h*fundamental_Hz*t),sin(2*pi*h*fundamental_Hz*t)];
    coefficient=M\x;
    harmonic_rms(h)=hypot(coefficient(1),coefficient(2))/sqrt(2);
end
if H<2 || harmonic_rms(1)<=eps
    thd_percent=NaN;
else
    thd_percent=100*sqrt(sum(harmonic_rms(2:end).^2))/harmonic_rms(1);
end
end

