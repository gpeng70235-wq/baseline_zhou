function [thd_percent,fundamental_rms,residual_rms] = ...
        phase_thd_total_rms(signal,time_s,fundamental_Hz)
%PHASE_THD_TOTAL_RMS Full-band distortion of a uniformly sampled waveform.
% A DC term and the known-frequency fundamental are fitted by least squares.
% The RMS residual contains all resolved switching harmonics/interharmonics.

x = signal(:);
t = time_s(:);
assert(numel(x)==numel(t) && numel(x)>3,'Zhou:InvalidTHDInput', ...
    'THD input signal/time sizes are invalid.');
M = [ones(size(t)),cos(2*pi*fundamental_Hz*t),sin(2*pi*fundamental_Hz*t)];
coefficient = M\x;
fundamental_rms = hypot(coefficient(2),coefficient(3))/sqrt(2);
residual = x-M*coefficient;
residual_rms = sqrt(mean(residual.^2));
if fundamental_rms <= eps
    thd_percent = NaN;
else
    thd_percent = 100*residual_rms/fundamental_rms;
end
end
