function R = phase_analysis(cfg,T,W,split,C,S)
%PHASE_ANALYSIS Cycle repeatability plus leave-cycle/case-out transfer.
fprintf('Phase 5: amplitude/phase repeatability and held-out transfer...\n');
R=repeatability(cfg,W,C,S);
zhou_periodic.write_table(R,fullfile(cfg.summary_dir,'harmonic_repeatability.csv'));
X=cycle_transfer(T,W,split);
zhou_periodic.write_table(X,fullfile(cfg.summary_dir,'cross_cycle_transfer.csv'));
Y=case_transfer(T,W,split);
zhou_periodic.write_table(Y,fullfile(cfg.summary_dir,'cross_case_transfer.csv'));
write_report(cfg,R,X,Y);
end

function R=repeatability(cfg,W,C,S)
rows=repmat(empty_repeat(),0,1);
ids=unique(C.case_id,'stable');
axes=["d","q","dq_positive","dq_negative"];
for cid=reshape(ids,1,[])
    wr=W(W.case_id==cid,:);
    for order=cfg.preregistered_orders
        sp=S(S.case_id==cid & S.order==order,:);
        for axis=axes
            z=C(C.case_id==cid & C.order==order & C.axis==axis,:);
            if isempty(z),continue;end
            r=empty_repeat();r.case_id=cid;r.evidence_role=wr.evidence_role;r.axis=axis;r.order=order;
            r.cycle_count=height(z);r.calibration_cycle_count=nnz(z.split=="calibration");
            r.validation_cycle_count=nnz(z.split=="validation");
            r.amplitude_mean=mean(z.amplitude);r.amplitude_std=std(z.amplitude);
            r.amplitude_cv=r.amplitude_std/max(r.amplitude_mean,eps);
            ph=mean(exp(1i*z.phase));r.circular_mean_phase=angle(ph);r.phase_resultant_R=abs(ph);
            r.mean_speed=wr.mean_speed;r.frequency_hz=order*wr.mean_electrical_frequency_hz;
            if isempty(sp)
                r.peak_snr_db=NaN;
            elseif axis=="d"
                r.peak_snr_db=20*log10(max(sp.amplitude_d,realmin)/max(sp.local_noise_floor_d,realmin));
            elseif axis=="q"
                r.peak_snr_db=20*log10(max(sp.amplitude_q,realmin)/max(sp.local_noise_floor_q,realmin));
            else
                r.peak_snr_db=sp.peak_snr_db;
            end
            cal=z(z.split=="calibration",:);val=z(z.split=="validation",:);
            pcal=mean(cal.complex_coefficient_real+1i*cal.complex_coefficient_imag);
            pval=mean(val.complex_coefficient_real+1i*val.complex_coefficient_imag);
            r.calibration_amplitude=mean(cal.amplitude);r.validation_amplitude=mean(val.amplitude);
            r.validation_to_calibration_amplitude_ratio=r.validation_amplitude/max(r.calibration_amplitude,eps);
            r.validation_phase_shift=abs(angle(pval*conj(pcal)));
            r.held_out_repeatable=r.validation_to_calibration_amplitude_ratio>=0.5 && ...
                r.validation_to_calibration_amplitude_ratio<=1.5 && r.validation_phase_shift<=pi/3;
            r.snr_pass=r.peak_snr_db>=cfg.minimum_peak_snr_db;
            r.cv_pass=r.amplitude_cv<=cfg.maximum_amplitude_cv;
            r.phase_pass=r.phase_resultant_R>=cfg.minimum_phase_R;
            r.stable_periodic_component=wr.evidence_role=="ENGINEERING_PRIMARY" && ...
                r.snr_pass && r.cv_pass && r.phase_pass && r.held_out_repeatable;
            rows(end+1,1)=r; %#ok<AGROW>
        end
    end
end
R=struct2table(rows,'AsArray',true);
end

function X=cycle_transfer(T,W,split)
rows=repmat(empty_transfer(),0,1);models=["6","12","6+12"];
ids=W.case_id(W.valid_for_order_tracking);
for cid=reshape(ids,1,[])
    c=T(T.case_id==cid,:);sr=split(split.case_id==cid,:);wr=W(W.case_id==cid,:);
    for held=1:height(sr)
        train=sr.cycle_id~=sr.cycle_id(held);test=sr.cycle_id==sr.cycle_id(held);
        A=cycle_rows(c,sr(train,:));B=cycle_rows(c,sr(test,:));
        for model=models
            [pd,pq]=fit_predict(A,B,model);
            r=empty_transfer();r.transfer_type="leave_one_cycle_out";r.case_id=cid;
            r.evidence_role=wr.evidence_role;r.held_out_id=string(sr.cycle_id(held));r.model=model;
            r.train_cycle_count=nnz(train);r.test_sample_count=height(B);
            r.rms_before=rms(complex(B.e_d,B.e_q));r.rms_after=rms(complex(B.e_d-pd,B.e_q-pq));
            r.rms_relative_reduction=1-r.rms_after/max(r.rms_before,eps);r.transfer_pass=r.rms_relative_reduction>0;
            r.valid=true;rows(end+1,1)=r; %#ok<AGROW>
        end
    end
end
X=struct2table(rows,'AsArray',true);
end

function Y=case_transfer(T,W,split)
rows=repmat(empty_transfer(),0,1);models=["6","12","6+12"];
primary=W(W.valid_for_order_tracking & W.evidence_role=="ENGINEERING_PRIMARY",:);
for k=1:height(primary)
    target=primary(k,:);donorMask=abs(primary.mean_speed-target.mean_speed)<=1 & primary.case_id~=target.case_id;
    donors=primary.case_id(donorMask);
    testSplit=split(split.case_id==target.case_id & split.split=="validation",:);
    B=cycle_rows(T(T.case_id==target.case_id,:),testSplit);
    trainParts=cell(numel(donors),1);
    for d=1:numel(donors)
        ds=split(split.case_id==donors(d) & split.split=="calibration",:);
        trainParts{d}=cycle_rows(T(T.case_id==donors(d),:),ds);
    end
    if isempty(trainParts),A=T([],:);else,A=vertcat(trainParts{:});end
    for model=models
        r=empty_transfer();r.transfer_type="leave_one_case_out_same_speed";r.case_id=target.case_id;
        r.evidence_role=target.evidence_role;r.held_out_id=target.case_id;r.model=model;
        r.donor_case_count=numel(donors);r.donor_cases=strjoin(donors,";");r.test_sample_count=height(B);
        if isempty(A)||isempty(B)
            r.valid=false;r.transfer_pass=false;
        else
            [pd,pq]=fit_predict(A,B,model);r.train_cycle_count=nnz(split.split=="calibration" & ismember(split.case_id,donors));
            r.rms_before=rms(complex(B.e_d,B.e_q));r.rms_after=rms(complex(B.e_d-pd,B.e_q-pq));
            r.rms_relative_reduction=1-r.rms_after/max(r.rms_before,eps);r.transfer_pass=r.rms_relative_reduction>0;r.valid=true;
        end
        rows(end+1,1)=r; %#ok<AGROW>
    end
end
Y=struct2table(rows,'AsArray',true);
end

function A=cycle_rows(c,sr)
mask=false(height(c),1);
for k=1:height(sr)
    mask=mask | (c.electrical_angle>=sr.theta_start(k) & c.electrical_angle<sr.theta_end(k));
end
A=c(mask,:);
end
function [pd,pq]=fit_predict(A,B,model)
XA=design(A.electrical_angle,model);XB=design(B.electrical_angle,model);
bd=XA\A.e_d;bq=XA\A.e_q;pd=XB*bd;pq=XB*bq;
end
function X=design(theta,model)
if model=="6",orders=6;elseif model=="12",orders=12;else,orders=[6 12];end
X=zeros(numel(theta),2*numel(orders));
for k=1:numel(orders),X(:,2*k-1:2*k)=[cos(orders(k)*theta),sin(orders(k)*theta)];end
end
function r=empty_repeat()
r=struct('case_id',"",'evidence_role',"",'axis',"",'order',0,'cycle_count',0, ...
    'calibration_cycle_count',0,'validation_cycle_count',0,'mean_speed',NaN, ...
    'frequency_hz',NaN,'amplitude_mean',NaN,'amplitude_std',NaN,'amplitude_cv',NaN, ...
    'circular_mean_phase',NaN,'phase_resultant_R',NaN,'peak_snr_db',NaN, ...
    'calibration_amplitude',NaN,'validation_amplitude',NaN, ...
    'validation_to_calibration_amplitude_ratio',NaN,'validation_phase_shift',NaN, ...
    'held_out_repeatable',false,'snr_pass',false,'cv_pass',false,'phase_pass',false, ...
    'stable_periodic_component',false);
end
function r=empty_transfer()
r=struct('transfer_type',"",'case_id',"",'evidence_role',"",'held_out_id',"", ...
    'model',"",'donor_case_count',0,'donor_cases',"",'train_cycle_count',0, ...
    'test_sample_count',0,'rms_before',NaN,'rms_after',NaN, ...
    'rms_relative_reduction',NaN,'transfer_pass',false,'valid',false);
end
function write_report(cfg,R,X,Y)
primary=R(R.evidence_role=="ENGINEERING_PRIMARY" & ismember(R.axis,["d","q"]),:);
stable6=unique(primary.case_id(primary.order==6 & primary.stable_periodic_component));
stable12=unique(primary.case_id(primary.order==12 & primary.stable_periodic_component));
cx=X(X.model=="6+12" & X.evidence_role=="ENGINEERING_PRIMARY",:);
cy=Y(Y.model=="6+12" & Y.valid,:);
L=["# Phase Coherence Report";""; ...
    "Amplitude and phase are evaluated per complete electrical cycle on the uniform-angle fits. Calibration and held-out validation cycles are never the same cycles.";""; ...
    "## Preregistered stability gates";""; ...
    "A case/axis/order passes only when full-window peak SNR >= "+cfg.minimum_peak_snr_db+" dB, cycle amplitude CV <= "+100*cfg.maximum_amplitude_cv+"%, circular R >= "+cfg.minimum_phase_R+", and calibration-to-validation amplitude/phase remain within the registered bounds.";""; ...
    "## Results";""; ...
    "- Stable 6th-order ENGINEERING_PRIMARY cases (at least one axis): **"+numel(stable6)+"**."; ...
    "- Stable 12th-order ENGINEERING_PRIMARY cases (at least one axis): **"+numel(stable12)+"**."; ...
    "- Leave-one-cycle-out 6+12 positive-RMS transfers: **"+nnz(cx.transfer_pass)+"/"+height(cx)+"**; median reduction `"+sprintf('%.3f%%',100*median(cx.rms_relative_reduction,'omitnan'))+"`."; ...
    "- Valid same-speed leave-one-case-out 6+12 positive transfers: **"+nnz(cy.transfer_pass)+"/"+height(cy)+"**; median reduction `"+sprintf('%.3f%%',100*median(cy.rms_relative_reduction,'omitnan'))+"`.";""; ...
    "Frequency synchronization is assessed from fixed order times measured electrical frequency; fixed-Hz alternatives are separated by the 300/400/500 rpm groups. No post-hoc order replaces the preregistered 6 and 12."];
writelines(L,fullfile(cfg.docs_dir,'PHASE_COHERENCE_REPORT.md'),'Encoding','UTF-8');
end
