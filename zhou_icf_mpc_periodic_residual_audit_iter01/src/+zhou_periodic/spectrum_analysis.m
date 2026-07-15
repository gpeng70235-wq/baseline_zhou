function S = spectrum_analysis(cfg, T, W)
%SPECTRUM_ANALYSIS Hann FFT plus exact unwindowed sinus regression.
fprintf('Phase 3: computing preregistered time spectra...\n');
rows = repmat(empty_row(),0,1);
for w = 1:height(W)
    wr = W(w,:);
    c = T(T.case_id==wr.case_id,:);
    if wr.valid_for_fft
        x = c(c.sample_index>=wr.start_sample & c.sample_index<=wr.end_sample,:);
        N = height(x); fs = cfg.fs_Hz; fe = wr.mean_electrical_frequency_hz;
        ed = detrend(x.e_d,'linear'); eq = detrend(x.e_q,'linear');
        win = hann(N,'periodic');
        Fd = fft(ed.*win); Fq = fft(eq.*win);
        scale = 2/sum(win);
        Adspec = scale*abs(Fd(1:floor(N/2)+1));
        Aqspec = scale*abs(Fq(1:floor(N/2)+1));
        fgrid = (0:floor(N/2))'*fs/N;
        baseEnergy = mean(ed.^2+eq.^2);
        for order = cfg.display_orders
            r=empty_row(); r.case_id=wr.case_id; r.window_id=wr.window_id;
            r.evidence_role=wr.evidence_role;r.order=order;r.frequency_hz=order*fe;
            r.frequency_resolution_hz=fs/N;r.order_resolution=fs/N/fe;
            r.sample_rate_hz=fs;r.nyquist_frequency_hz=fs/2;r.nyquist_order=wr.nyquist_order;
            r.aliasing_flag=r.frequency_hz>=fs/2;
            idx=round(r.frequency_hz/fs*N)+1; idx=max(2,min(idx,numel(fgrid)));
            r.fft_bin_frequency_hz=fgrid(idx);
            r.fft_amplitude_d=Adspec(idx);r.fft_amplitude_q=Aqspec(idx);
            r.fft_phase_d=angle(Fd(idx));r.fft_phase_q=angle(Fq(idx));
            tt=x.time_s-mean(x.time_s);th=x.electrical_angle;
            X=[ones(N,1),tt,cos(order*th),sin(order*th)];
            bd=X\x.e_d;bq=X\x.e_q;
            r.amplitude_d=hypot(bd(3),bd(4));r.amplitude_q=hypot(bq(3),bq(4));
            r.complex_amplitude=hypot(r.amplitude_d,r.amplitude_q);
            r.phase_d=atan2(-bd(4),bd(3));r.phase_q=atan2(-bq(4),bq(3));
            neighbor=abs(fgrid-r.frequency_hz)<=2*fe & abs(fgrid-r.frequency_hz)>=0.5*fe;
            neighbor(1)=false;
            if nnz(neighbor)<3
                neighbor=max(2,idx-5):min(numel(fgrid),idx+5);neighbor=setdiff(neighbor,max(1,idx-1):min(numel(fgrid),idx+1));
            end
            r.local_noise_floor_d=median(Adspec(neighbor),'omitnan');
            r.local_noise_floor_q=median(Aqspec(neighbor),'omitnan');
            r.local_noise_floor=hypot(r.local_noise_floor_d,r.local_noise_floor_q);
            r.peak_snr_db=20*log10(max(r.complex_amplitude,realmin)/max(r.local_noise_floor,realmin));
            r.energy_share=((r.amplitude_d^2+r.amplitude_q^2)/2)/max(baseEnergy,realmin);
            r.leakage_fraction=abs(r.complex_amplitude-hypot(r.fft_amplitude_d,r.fft_amplitude_q))/max(r.complex_amplitude,eps);
            r.validity="VALID"; if r.aliasing_flag,r.validity="INVALID_ALIASING";end
            rows(end+1,1)=r; %#ok<AGROW>
        end
    else
        for order=cfg.display_orders
            r=empty_row();r.case_id=wr.case_id;r.window_id=wr.window_id;r.evidence_role=wr.evidence_role;
            r.order=order;r.frequency_hz=order*wr.mean_electrical_frequency_hz;
            r.sample_rate_hz=cfg.fs_Hz;r.nyquist_frequency_hz=cfg.fs_Hz/2;r.nyquist_order=wr.nyquist_order;
            r.aliasing_flag=r.frequency_hz>=cfg.fs_Hz/2;r.validity="EXCLUDED:"+wr.exclusion_reason;
            rows(end+1,1)=r; %#ok<AGROW>
        end
    end
end
S=struct2table(rows,'AsArray',true);
zhou_periodic.write_table(S,fullfile(cfg.summary_dir,'time_spectrum.csv'));
P=S(ismember(S.order,cfg.preregistered_orders),:);
zhou_periodic.write_table(P,fullfile(cfg.summary_dir,'order_peak_table.csv'));
end

function r=empty_row()
r=struct('case_id',"",'window_id',"",'evidence_role',"",'order',NaN, ...
    'frequency_hz',NaN,'frequency_resolution_hz',NaN,'order_resolution',NaN, ...
    'sample_rate_hz',NaN,'nyquist_frequency_hz',NaN,'nyquist_order',NaN, ...
    'fft_bin_frequency_hz',NaN,'fft_amplitude_d',NaN,'fft_amplitude_q',NaN, ...
    'fft_phase_d',NaN,'fft_phase_q',NaN,'amplitude_d',NaN,'amplitude_q',NaN, ...
    'complex_amplitude',NaN,'phase_d',NaN,'phase_q',NaN, ...
    'local_noise_floor_d',NaN,'local_noise_floor_q',NaN,'local_noise_floor',NaN, ...
    'peak_snr_db',NaN,'energy_share',NaN,'leakage_fraction',NaN, ...
    'aliasing_flag',false,'validity',"");
end
