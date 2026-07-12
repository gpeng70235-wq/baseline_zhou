function thd = calculate_thd(signal)
%CALCULATE_THD FFT-bin THD ratio for a periodic, uniformly sampled signal.
signal = signal(:);
assert(numel(signal)>=4 && all(isfinite(signal)), ...
    'ZhouIPMSM:InvalidTHDInput','THD requires at least four finite samples.');
signal = signal-mean(signal);
spectrum = abs(fft(signal));
positive = spectrum(2:floor(numel(signal)/2)+1);
if max(positive)<=eps(max(1,norm(signal)))
    thd = 0;
    return;
end
[fundamental,fundamental_index] = max(positive);
harmonic_power = sum(positive.^2)-positive(fundamental_index).^2;
thd = sqrt(max(0,harmonic_power))/max(fundamental,eps);
end
