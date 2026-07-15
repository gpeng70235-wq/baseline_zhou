function C = order_analysis(cfg, T, W, split)
%ORDER_ANALYSIS Uniform-angle resampling and preregistered 6/12 fits.
fprintf('Phase 4: electrical-angle order tracking on uniform grids...\n');
rows=repmat(empty_row(),0,1);
specRows=repmat(empty_spectrum_row(),0,1);
validCases=W.case_id(W.valid_for_order_tracking);
for cid=reshape(validCases,1,[])
    c=T(T.case_id==cid,:); sr=split(split.case_id==cid,:);
    wr=W(W.case_id==cid,:);
    for q=1:height(sr)
        n=cfg.angle_points_per_cycle;
        theta=sr.theta_start(q)+(0:n-1)'*(2*pi/n);
        nativeMask=c.electrical_angle>=sr.theta_start(q) & c.electrical_angle<sr.theta_end(q) & ...
            c.sample_index>=wr.start_sample & c.sample_index<=wr.end_sample;
        native=c(nativeMask,:);
        ed=interp1(c.electrical_angle,c.e_d,theta,'linear','extrap');
        eq=interp1(c.electrical_angle,c.e_q,theta,'linear','extrap');
        inside=theta>=min(native.electrical_angle) & theta<=max(native.electrical_angle);
        extrapFraction=1-mean(inside);
        if height(native)>1
            edBack=interp1(theta,ed,native.electrical_angle,'linear','extrap');
            eqBack=interp1(theta,eq,native.electrical_angle,'linear','extrap');
            interpRmse=hypot(rms(native.e_d-edBack),rms(native.e_q-eqBack));
        else
            interpRmse=NaN;
        end
        X=[ones(n,1),cos(6*theta),sin(6*theta),cos(12*theta),sin(12*theta)];
        bd=X\ed;bq=X\eq;bz=X\complex(ed,eq);
        residualVectorRms=rms(complex(ed-X*bd,eq-X*bq));
        for displayOrder=cfg.display_orders
            Xo=[ones(n,1),cos(displayOrder*theta),sin(displayOrder*theta)];
            bod=Xo\ed;boq=Xo\eq;so=empty_spectrum_row();so.case_id=cid;so.window_id=wr.window_id;
            so.cycle_id=sr.cycle_id(q);so.split=sr.split(q);so.evidence_role=wr.evidence_role;
            so.order=displayOrder;so.amplitude_d=hypot(bod(2),bod(3));so.amplitude_q=hypot(boq(2),boq(3));
            so.complex_amplitude=hypot(so.amplitude_d,so.amplitude_q);so.phase_d=atan2(-bod(3),bod(2));
            so.phase_q=atan2(-boq(3),boq(2));specRows(end+1,1)=so; %#ok<AGROW>
        end
        for order=cfg.preregistered_orders
            if order==6, ix=[2 3]; else, ix=[4 5]; end
            rows(end+1,1)=make_real(cid,wr.window_id,sr(q,:),"d",order,bd(1),bd(ix), ...
                residualVectorRms,interpRmse,extrapFraction,wr.evidence_role); %#ok<AGROW>
            rows(end+1,1)=make_real(cid,wr.window_id,sr(q,:),"q",order,bq(1),bq(ix), ...
                residualVectorRms,interpRmse,extrapFraction,wr.evidence_role); %#ok<AGROW>
            rows(end+1,1)=make_complex(cid,wr.window_id,sr(q,:),"dq_positive",order,bz(1),bz(ix),1, ...
                residualVectorRms,interpRmse,extrapFraction,wr.evidence_role); %#ok<AGROW>
            rows(end+1,1)=make_complex(cid,wr.window_id,sr(q,:),"dq_negative",order,bz(1),bz(ix),-1, ...
                residualVectorRms,interpRmse,extrapFraction,wr.evidence_role); %#ok<AGROW>
        end
    end
end
C=struct2table(rows,'AsArray',true);
zhou_periodic.write_table(C,fullfile(cfg.summary_dir,'order_tracking_coefficients.csv'));
A=struct2table(specRows,'AsArray',true);
zhou_periodic.write_table(A,fullfile(cfg.summary_dir,'angle_order_spectrum.csv'));
write_protocol(cfg,C,W);
end

function r=make_real(cid,wid,sr,axis,order,c0,b,resRms,interpRmse,extrapFrac,role)
r=empty_row();r.case_id=cid;r.window_id=wid;r.cycle_id=sr.cycle_id;r.split=sr.split;
r.evidence_role=role;r.axis=axis;r.order=order;r.c0_real=real(c0);r.c0_imag=0;
r.c_cos_real=real(b(1));r.c_sin_real=real(b(2));r.c_cos_imag=0;r.c_sin_imag=0;
r.amplitude=hypot(real(b(1)),real(b(2)));r.phase=atan2(-real(b(2)),real(b(1)));
r.complex_coefficient_real=real(b(1));r.complex_coefficient_imag=-real(b(2));
r.residual_vector_rms=resRms;r.interpolation_rmse=interpRmse;
r.extrapolated_grid_fraction=extrapFrac;r.angle_points=256;r.valid=true;
end
function r=make_complex(cid,wid,sr,axis,order,c0,b,signDir,resRms,interpRmse,extrapFrac,role)
r=empty_row();r.case_id=cid;r.window_id=wid;r.cycle_id=sr.cycle_id;r.split=sr.split;
r.evidence_role=role;r.axis=axis;r.order=order;r.c0_real=real(c0);r.c0_imag=imag(c0);
r.c_cos_real=real(b(1));r.c_cos_imag=imag(b(1));r.c_sin_real=real(b(2));r.c_sin_imag=imag(b(2));
if signDir==1, phasor=b(1)-1i*b(2); else, phasor=b(1)+1i*b(2); end
r.amplitude=abs(phasor);r.phase=angle(phasor);
r.complex_coefficient_real=real(phasor);r.complex_coefficient_imag=imag(phasor);
r.residual_vector_rms=resRms;r.interpolation_rmse=interpRmse;
r.extrapolated_grid_fraction=extrapFrac;r.angle_points=256;r.valid=true;
end
function r=empty_row()
r=struct('case_id',"",'window_id',"",'cycle_id',0,'split',"",'evidence_role',"", ...
    'axis',"",'order',0,'c0_real',NaN,'c0_imag',NaN,'c_cos_real',NaN, ...
    'c_cos_imag',NaN,'c_sin_real',NaN,'c_sin_imag',NaN,'amplitude',NaN, ...
    'phase',NaN,'complex_coefficient_real',NaN,'complex_coefficient_imag',NaN, ...
    'residual_vector_rms',NaN,'interpolation_rmse',NaN, ...
    'extrapolated_grid_fraction',NaN,'angle_points',0,'valid',false);
end
function r=empty_spectrum_row()
r=struct('case_id',"",'window_id',"",'cycle_id',0,'split',"",'evidence_role',"", ...
    'order',0,'amplitude_d',NaN,'amplitude_q',NaN,'complex_amplitude',NaN, ...
    'phase_d',NaN,'phase_q',NaN);
end
function write_protocol(cfg,C,W)
valid=W(W.valid_for_order_tracking,:);
L=["# Order Tracking Protocol";""; ...
    "Time FFT is not the mechanism test. Each registered complete cycle is independently resampled from native samples to a uniform rotor-electrical-angle grid.";""; ...
    "## Implementation";""; ...
    "- Grid density: **"+cfg.angle_points_per_cycle+" points per electrical cycle**."; ...
    "- Interpolation: linear; the small endpoint extrapolation fraction and native-grid round-trip RMS are retained per coefficient row."; ...
    "- Real-axis fit: `c0+c6c cos(6 theta)+c6s sin(6 theta)+c12c cos(12 theta)+c12s sin(12 theta)`."; ...
    "- Amplitude: `sqrt(c_cos^2+c_sin^2)`; phase: `atan2(-c_sin,c_cos)`."; ...
    "- Complex residual: positive- and negative-rotating coefficients are both retained, so rotation direction is not selected after seeing the result."; ...
    "- Fits are per complete cycle. Calibration and validation labels come only from the preregistered time split.";""; ...
    "## Coverage";""; ...
    "Valid windows: **"+height(valid)+"**; cycles: **"+sum(valid.electrical_cycles)+"**; coefficient rows: **"+height(C)+"**."; ...
    "The maximum interpolation round-trip RMS is `"+sprintf('%.6g',max(C.interpolation_rmse,[],'omitnan'))+" A`; maximum endpoint extrapolated fraction is `"+sprintf('%.6g',max(C.extrapolated_grid_fraction))+"`.";""; ...
    "Fixed-speed windows are evaluated by both this angle-domain method and the independent Hann-FFT/exact-regression table."];
writelines(L,fullfile(cfg.docs_dir,'ORDER_TRACKING_PROTOCOL.md'),'Encoding','UTF-8');
end
