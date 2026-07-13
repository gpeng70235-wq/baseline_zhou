function [metrics,spectrum,windowed] = calculate_steady_state_thd(varargin)
%CALCULATE_STEADY_STATE_THD THD on an explicitly integer-cycle window.
% Dense source samples are linearly resampled onto an exact integer number
% of electrical periods. The primary THD is total nonfundamental RMS divided
% by fundamental RMS; a harmonic-only THD is reported separately.

[waveform,electrical_frequency_Hz,steady_start_s,steady_end_s, ...
    signal_name,max_harmonic,vector_time] = parse_inputs(varargin{:});
validateattributes(electrical_frequency_Hz,{'double'}, ...
    {'scalar','positive','finite'});
validateattributes(max_harmonic,{'double'}, ...
    {'scalar','integer','>=',1,'finite'});

if isempty(vector_time)
    [time_s,signal,signal_name] = waveform_columns(waveform,string(signal_name));
else
    signal=double(waveform(:));time_s=double(vector_time(:));
    signal_name="signal_A";
end
assert(numel(time_s)>=4 && all(isfinite([time_s;signal])) && ...
    all(diff(time_s)>0),'ZhouValidation:THDWaveform', ...
    'THD waveform must contain finite, strictly increasing samples.');
dt=median(diff(time_s));
fs=1/dt;
if isempty(steady_start_s), steady_start_s=time_s(1); end
if isempty(steady_end_s), steady_end_s=time_s(end); end
validateattributes(steady_start_s,{'double'},{'scalar','finite'});
validateattributes(steady_end_s,{'double'}, ...
    {'scalar','finite','>',steady_start_s});

window_start=max(steady_start_s,time_s(1));
available_end=min(steady_end_s,time_s(end)+dt);
cycles=floor((available_end-window_start)*electrical_frequency_Hz+1e-10);
assert(cycles>=1,'ZhouValidation:THDWindow', ...
    'Steady-state interval must contain at least one electrical cycle.');
window_end=window_start+cycles/electrical_frequency_Hz;

% Resampling makes the spectral window exactly periodic even when the raw
% waveform grid has a noninteger number of samples per electrical cycle.
samples_per_cycle=max(2*(max_harmonic+1),round(fs/electrical_frequency_Hz));
sample_count=cycles*samples_per_cycle;
resampled_dt=1/(electrical_frequency_Hz*samples_per_cycle);
time_grid=window_start+(0:sample_count-1).'*resampled_dt;
assert(time_grid(end)<=time_s(end)+10*eps(time_s(end)), ...
    'ZhouValidation:THDInterpolation','Integer-cycle grid exceeds source data.');
signal_grid=interp1(time_s,signal,time_grid,'linear');
assert(all(isfinite(signal_grid)),'ZhouValidation:THDInterpolation', ...
    'Integer-cycle interpolation produced nonfinite samples.');

N=numel(signal_grid);
coefficient=fft(signal_grid)/N;
dc=real(coefficient(1));
max_resolvable=floor((N-1)/(2*cycles));
used_max_harmonic=min(max_harmonic,max_resolvable);
assert(used_max_harmonic>=1,'ZhouValidation:THDSpectrum', ...
    'Resampled window cannot resolve the fundamental.');

harmonic_order=(0:used_max_harmonic).';
frequency_Hz=harmonic_order*electrical_frequency_Hz;
peak_amplitude=zeros(size(harmonic_order));
peak_amplitude(1)=abs(dc);
for h=1:used_max_harmonic
    bin=h*cycles+1;
    peak_amplitude(h+1)=2*abs(coefficient(bin));
end
rms_amplitude=peak_amplitude/sqrt(2);
rms_amplitude(1)=abs(dc);
power=rms_amplitude.^2;
fundamental_peak=peak_amplitude(2);
fundamental_rms=rms_amplitude(2);
assert(fundamental_rms>sqrt(eps),'ZhouValidation:THDFundamental', ...
    'Fundamental RMS is too small for a finite THD ratio.');

sample_index=(0:N-1).';
fundamental_bin=cycles+1;
fundamental=2*real(coefficient(fundamental_bin).* ...
    exp(1i*2*pi*cycles*sample_index/N));
residual=signal_grid-dc-fundamental;
nonfundamental_power=mean(residual.^2);
harmonic_power=sum(power(3:end));
total_rms=sqrt(mean(signal_grid.^2));
nonfundamental_rms=sqrt(max(nonfundamental_power,0));
thd_ratio=nonfundamental_rms/fundamental_rms;
harmonic_thd_ratio=sqrt(max(harmonic_power,0))/fundamental_rms;

metrics=struct();
metrics.signal=signal_name;
metrics.electrical_frequency_Hz=electrical_frequency_Hz;
metrics.requested_steady_start_s=steady_start_s;
metrics.requested_steady_end_s=steady_end_s;
metrics.steady_window_start_s=window_start;
metrics.steady_window_end_s=window_end;
metrics.steady_start_s=window_start;
metrics.steady_end_s=window_end;
metrics.electrical_cycles=cycles;
metrics.window_samples=N;
metrics.sample_count=N;
metrics.samples_per_electrical_cycle=samples_per_cycle;
metrics.source_sample_period_s=dt;
metrics.analysis_sample_period_s=resampled_dt;
metrics.dc_component_A=dc;
metrics.total_rms_A=total_rms;
metrics.fundamental_peak_A=fundamental_peak;
metrics.fundamental_rms_A=fundamental_rms;
metrics.nonfundamental_power_A2=nonfundamental_power;
metrics.harmonic_power_A2=harmonic_power;
metrics.harmonic_rms_A=sqrt(max(harmonic_power,0));
metrics.nonfundamental_rms_A=nonfundamental_rms;
metrics.thd_ratio=thd_ratio;
metrics.thd_percent=100*thd_ratio;
metrics.harmonic_thd_ratio=harmonic_thd_ratio;
metrics.harmonic_thd_percent=100*harmonic_thd_ratio;
metrics.max_harmonic=used_max_harmonic;
spectrum=table(harmonic_order,frequency_Hz,peak_amplitude,rms_amplitude, ...
    power,'VariableNames',{'harmonic_order','frequency_Hz', ...
    'peak_amplitude_A','rms_A','power_A2'});
windowed=table(time_grid,signal_grid,fundamental,residual, ...
    'VariableNames',{'time_s','signal_A','fundamental_A','residual_A'});
end

function [waveform,f,start_time,end_time,signal_name,max_harmonic,vector_time] = ...
        parse_inputs(varargin)
assert(nargin>=2,'ZhouValidation:THDArguments', ...
    'THD requires waveform data and electrical frequency.');
vector_time=[];signal_name="";max_harmonic=40;
% Backward-compatible vector form: (signal,time,f,start,end[,maxH]).
if nargin>=3 && isnumeric(varargin{1}) && isvector(varargin{1}) && ...
        isnumeric(varargin{2}) && isvector(varargin{2}) && ...
        ~isscalar(varargin{2})
    waveform=varargin{1};vector_time=varargin{2};f=varargin{3};
    if nargin>=4, start_time=varargin{4}; else, start_time=[]; end
    if nargin>=5, end_time=varargin{5}; else, end_time=[]; end
    if nargin>=6 && ~isempty(varargin{6}), max_harmonic=varargin{6}; end
else
    waveform=varargin{1};f=varargin{2};
    if nargin>=3, start_time=varargin{3}; else, start_time=[]; end
    if nargin>=4, end_time=varargin{4}; else, end_time=[]; end
    if nargin>=5 && ~isempty(varargin{5}), signal_name=string(varargin{5}); end
    if nargin>=6 && ~isempty(varargin{6}), max_harmonic=varargin{6}; end
end
end

function [time_s,signal,name] = waveform_columns(waveform,requested_name)
if istable(waveform)
    vars=string(waveform.Properties.VariableNames);
    assert(ismember("time_s",vars),'ZhouValidation:THDTime', ...
        'Waveform table must contain time_s.');
    if strlength(requested_name)==0
        candidates=["ia_A" "signal_A" "current_A" "id_A"];
        idx=find(ismember(candidates,vars),1);
        assert(~isempty(idx),'ZhouValidation:THDSignal', ...
            'Specify signal_name for the waveform table.');
        name=candidates(idx);
    else
        assert(ismember(requested_name,vars),'ZhouValidation:THDSignal', ...
            'Waveform table does not contain %s.',requested_name);
        name=requested_name;
    end
    time_s=double(waveform.time_s(:));
    signal=double(waveform.(char(name))(:));
elseif isnumeric(waveform) && size(waveform,2)==2
    time_s=double(waveform(:,1));signal=double(waveform(:,2));
    if strlength(requested_name)==0, name="signal_A"; else, name=requested_name; end
elseif isstruct(waveform) && isfield(waveform,'time_s') && ...
        isfield(waveform,'signal')
    time_s=double(waveform.time_s(:));signal=double(waveform.signal(:));
    if strlength(requested_name)==0, name="signal_A"; else, name=requested_name; end
else
    error('ZhouValidation:THDInput', ...
        'Use a waveform table, [time signal] matrix, or time_s/signal struct.');
end
assert(numel(time_s)==numel(signal),'ZhouValidation:THDShape', ...
    'Waveform time and signal lengths differ.');
end
