function R=residual_spectrum(project,T)
%RESIDUAL_SPECTRUM Integer-electrical-cycle rectangular-window spectra.
rows=repmat(template(),0,1);fs=1/project.paper.Ts_s;
for caseId=unique(T.case_id,'stable').'
    ix=find(T.case_id==caseId&T.phase=="steady");speed=mean(T.speed_rpm(T.case_id==caseId),'omitnan');
    fe=project.paper.pole_pairs*speed/60;[window,cycles,reason]=coherent_window(ix,fe,fs,project.model_error.minimum_spectrum_cycles);
    for p=project.model_error.predictor_names
        for axis=["d","q"]
            r=template();r.case_id=caseId;r.axis=axis;r.predictor=p;r.electrical_frequency_Hz=fe;
            r.mean_speed_rpm=speed;r.speed_std_rpm=std(T.speed_rpm(window),'omitnan');r.invalid_reason=reason;
            if isempty(window),rows(end+1)=r;continue,end %#ok<AGROW>
            if axis=="d",x=T.("ed_"+p)(window);else,x=T.("eq_"+p)(window);end
            r.window_start_index=T.sample_index(window(1));r.window_end_index=T.sample_index(window(end));
            r.window_start_s=T.time_s(window(1));r.window_end_s=T.time_s(window(end));r.sample_count=numel(window);
            r.electrical_cycle_count=cycles;r.integer_cycle_error=abs(numel(window)*fe/fs-cycles);
            r.reference_rate_max_A_s=max(abs(T.reference_rate_A_s(window)),[],'omitnan');
            if any(~isfinite(x))||r.reference_rate_max_A_s>1e-6||r.speed_std_rpm>1e-9
                r.invalid_reason="nonfinite residual, changing reference, or changing speed";rows(end+1)=r;continue
            end
            r.residual_mean_A=mean(x);z=x-r.residual_mean_A;r.residual_ac_rms_A=sqrt(mean(z.^2));
            [amplitude,orders]=one_sided_rms(z,cycles);r.order1_rms_A=at_order(amplitude,orders,1);
            r.order6_rms_A=at_order(amplitude,orders,6);r.order12_rms_A=at_order(amplitude,orders,12);
            threshold=max(1e-8,1e-3*r.residual_ac_rms_A);r.fundamental_valid=isfinite(r.order1_rms_A)&&r.order1_rms_A>=threshold;
            if r.fundamental_valid,r.order6_over_order1=r.order6_rms_A/r.order1_rms_A;r.order12_over_order1=r.order12_rms_A/r.order1_rms_A;end
            [~,ord]=sort(amplitude,'descend');ord=ord(isfinite(amplitude(ord))&orders(ord)>0);ord=ord(1:min(3,numel(ord)));
            if numel(ord)>=1,r.dominant_order_1=orders(ord(1));r.dominant_amplitude_1_A=amplitude(ord(1));end
            if numel(ord)>=2,r.dominant_order_2=orders(ord(2));r.dominant_amplitude_2_A=amplitude(ord(2));end
            if numel(ord)>=3,r.dominant_order_3=orders(ord(3));r.dominant_amplitude_3_A=amplitude(ord(3));end
            r.spectrum_valid=true;r.invalid_reason="";rows(end+1)=r; %#ok<AGROW>
        end
    end
end
R=struct2table(rows,'AsArray',true);
end

function [window,cycles,reason]=coherent_window(ix,fe,fs,minCycles)
window=[];cycles=NaN;reason="";
if isempty(ix)||~isfinite(fe)||fe<=0,reason="no steady samples or nonpositive electrical frequency";return,end
maxCycles=floor(numel(ix)*fe/fs);
for c=maxCycles:-1:minCycles
    n=c*fs/fe;if abs(n-round(n))<=1e-10&&round(n)<=numel(ix),n=round(n);window=ix(end-n+1:end);cycles=c;return,end
end
reason="fewer than three coherent electrical cycles in steady trace";
end

function [a,orders]=one_sided_rms(x,cycles)
n=numel(x);Y=fft(x(:))/n;k=(0:floor(n/2)).';a=sqrt(2)*abs(Y(k+1));
if mod(n,2)==0,a(end)=abs(Y(n/2+1));end
a(1)=abs(Y(1));orders=k/cycles;
end

function value=at_order(a,o,target)
[gap,ix]=min(abs(o-target));if isempty(ix)||gap>1e-10,value=NaN;else,value=a(ix);end
end

function r=template()
r=struct('case_id',"",'axis',"",'predictor',"",'window_start_index',NaN,'window_end_index',NaN, ...
    'window_start_s',NaN,'window_end_s',NaN,'mean_speed_rpm',NaN,'speed_std_rpm',NaN, ...
    'electrical_frequency_Hz',NaN,'electrical_cycle_count',NaN,'sample_count',0,'integer_cycle_error',NaN, ...
    'reference_rate_max_A_s',NaN,'residual_mean_A',NaN,'residual_ac_rms_A',NaN, ...
    'order1_rms_A',NaN,'order6_rms_A',NaN,'order12_rms_A',NaN,'order6_over_order1',NaN, ...
    'order12_over_order1',NaN,'dominant_order_1',NaN,'dominant_amplitude_1_A',NaN, ...
    'dominant_order_2',NaN,'dominant_amplitude_2_A',NaN,'dominant_order_3',NaN, ...
    'dominant_amplitude_3_A',NaN,'fundamental_valid',false,'spectrum_valid',false,'invalid_reason',"");
end
