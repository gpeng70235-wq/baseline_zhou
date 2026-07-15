function manifest=generate_figures(cfg)
%GENERATE_FIGURES Produce the 16 preregistered diagnostic figures.
fprintf('Generating 16 registered figures...\n');
T=readtable(cfg.canonical_csv,'TextType','string');
W=readtable(fullfile(cfg.summary_dir,'window_registry.csv'),'TextType','string');
S=readtable(fullfile(cfg.summary_dir,'time_spectrum.csv'),'TextType','string');
C=readtable(fullfile(cfg.summary_dir,'order_tracking_coefficients.csv'),'TextType','string');
A=readtable(fullfile(cfg.summary_dir,'angle_order_spectrum.csv'),'TextType','string');
R=readtable(fullfile(cfg.summary_dir,'harmonic_repeatability.csv'),'TextType','string');
B=readtable(fullfile(cfg.summary_dir,'false_safe_phase_bins.csv'),'TextType','string');
E=readtable(fullfile(cfg.summary_dir,'event_window_metrics.csv'),'TextType','string');
M=read_forced(fullfile(cfg.summary_dir,'counterfactual_metrics.csv'),"model");
K=read_forced(fullfile(cfg.summary_dir,'counterfactual_case_metrics.csv'),"model");
spec={ ...
 '01_time_domain_residuals.png',@()fig_time(T,W); ...
 '02_time_fft.png',@()fig_spectrum(S,'fft'); ...
 '03_electrical_angle_order_spectrum.png',@()fig_angle_spectrum(A); ...
 '04_order6_amplitude_across_cycles.png',@()fig_amp(C,6); ...
 '05_order12_amplitude_across_cycles.png',@()fig_amp(C,12); ...
 '06_order6_phase_circle.png',@()fig_phase(C,6); ...
 '07_order12_phase_circle.png',@()fig_phase(C,12); ...
 '08_order_frequency_speed_sync.png',@()fig_sync(S); ...
 '09_false_safe_electrical_phase.png',@()fig_phase_bins(B); ...
 '10_false_safe_event_window.png',@()fig_event(E); ...
 '11_B0_vs_offline_order6.png',@()fig_model(M,'6'); ...
 '12_B0_vs_offline_order12.png',@()fig_model(M,'12'); ...
 '13_B0_vs_offline_order6_12.png',@()fig_model(M,'6+12'); ...
 '14_case_false_safe_improvement.png',@()fig_case(K); ...
 '15_train_validation_comparison.png',@()fig_train_validation(R); ...
 '16_normal_vs_stress_comparison.png',@()fig_range(T)};
file=strings(size(spec,1),1);generated=false(size(file));message=strings(size(file));
old=get(groot,'defaultFigureVisible');set(groot,'defaultFigureVisible','off');cleanup=onCleanup(@()set(groot,'defaultFigureVisible',old)); %#ok<NASGU>
for k=1:size(spec,1)
    file(k)=spec{k,1};
    try
        f=figure('Color','w','Position',[100 100 1120 680]);spec{k,2}();
        exportgraphics(f,fullfile(cfg.figure_dir,file(k)),'Resolution',160);close(f);generated(k)=true;
    catch ME
        message(k)=string(ME.message);if exist('f','var')&&isgraphics(f),close(f);end
    end
end
manifest=table(file,generated,message);zhou_periodic.write_table(manifest,fullfile(cfg.figure_dir,'figure_manifest.csv'));
assert(all(generated),'One or more registered figures failed; inspect figure_manifest.csv.');
end

function fig_time(T,W)
ids=W.case_id(W.valid_for_fft & W.evidence_role=="ENGINEERING_PRIMARY");ids=ids([1,ceil(end/2),end]);
tl=tiledlayout(3,1,'TileSpacing','compact');
for k=1:numel(ids)
    nexttile;c=T(T.case_id==ids(k),:);plot(1e3*c.time_s,c.e_d,'LineWidth',1);hold on;plot(1e3*c.time_s,c.e_q,'LineWidth',1);
    ylabel('A');title(strrep(ids(k),'_','\_'));grid on;
end
xlabel(tl,'Time (ms)');title(tl,'B0 k-to-k+2 prediction residuals across registered cohorts');legend('e_d','e_q','Location','best');
end
function fig_spectrum(S,kind)
P=S(S.validity=="VALID" & S.evidence_role=="ENGINEERING_PRIMARY",:);orders=unique(P.order);med=zeros(numel(orders),1);lo=med;hi=med;
for k=1:numel(orders),x=P.complex_amplitude(P.order==orders(k));med(k)=median(x);lo(k)=min(x);hi(k)=max(x);end
errorbar(orders,1e3*med,1e3*(med-lo),1e3*(hi-med),'o-','LineWidth',1.2);hold on;xline(6,'--r','6th');xline(12,'--m','12th');grid on;
xlabel('Electrical order');ylabel('Vector peak amplitude (mA)');
if kind=="fft",title('Hann FFT / exact-regression time spectrum');else,title('Electrical-angle order spectrum');end
end
function fig_angle_spectrum(A)
P=A(A.evidence_role=="ENGINEERING_PRIMARY",:);orders=unique(P.order);med=zeros(numel(orders),1);lo=med;hi=med;
for k=1:numel(orders),x=P.complex_amplitude(P.order==orders(k));med(k)=median(x);lo(k)=min(x);hi(k)=max(x);end
errorbar(orders,1e3*med,1e3*(med-lo),1e3*(hi-med),'o-','LineWidth',1.2);hold on;xline(6,'--r','6th');xline(12,'--m','12th');grid on;
xlabel('Electrical order');ylabel('Uniform-angle vector amplitude (mA)');title('256-point/cycle electrical-angle order spectrum');
end
function fig_amp(C,order)
P=C(C.order==order & C.evidence_role=="ENGINEERING_PRIMARY" & ismember(C.axis,["d","q"]),:);
cats=categorical(P.case_id,unique(P.case_id,'stable'));gscatter(double(cats),1e3*P.amplitude,P.axis,[],'.',16);grid on;
xticks(1:numel(categories(cats)));xticklabels(strrep(categories(cats),'_',' '));xtickangle(35);ylabel('Amplitude (mA)');title(sprintf('%dth-order amplitude by held cycle',order));
end
function fig_phase(C,order)
P=C(C.order==order & C.evidence_role=="ENGINEERING_PRIMARY" & C.axis=="dq_positive",:);polaraxes;
polarscatter(P.phase,1e3*P.amplitude,28,double(P.cycle_id),'filled');title(sprintf('%dth-order positive-rotating phase by cycle',order));colorbar;
end
function fig_sync(S)
P=S(S.validity=="VALID" & S.evidence_role=="ENGINEERING_PRIMARY" & ismember(S.order,[6 12]),:);fe=P.frequency_hz./P.order;
gscatter(fe,P.fft_bin_frequency_hz,P.order,lines(2),'ox',8);hold on;x=linspace(min(fe),max(fe),100);plot(x,6*x,'--');plot(x,12*x,'--');grid on;
xlabel('Electrical frequency (Hz)');ylabel('Measured FFT-bin frequency (Hz)');title('Order frequency follows electrical speed');legend('6th','12th','6 f_e','12 f_e','Location','northwest');
end
function fig_phase_bins(B)
P=B(B.case_id=="__ALL_PRIMARY__",:);tl=tiledlayout(2,1,'TileSpacing','compact');
for order=[6 12]
    nexttile;Q=P(P.order==order,:);ctr=(Q.phase_start+Q.phase_end)/2;bar(ctr,100*Q.false_safe_rate,1);ylabel('FS rate (%)');
    title(sprintf('%dth-order held-out phase bins, n_{FS}=%d',order,max(Q.total_false_safe_events)));grid on;
end
xlabel(tl,'Harmonic phase (rad)');
end
function fig_event(E)
P=E(E.evidence_role=="ENGINEERING_PRIMARY",:);offs=unique(P.offset_samples);tl=tiledlayout(2,1,'TileSpacing','compact');
for metric=["mean_residual_magnitude","mean_periodic_6_magnitude"]
    nexttile;
    for cohort=["false_safe","matched_control"]
        y=arrayfun(@(o)mean(P.(metric)(P.offset_samples==o&P.cohort==cohort),'omitnan'),offs);plot(offs,1e3*y,'LineWidth',1.4);hold on;
    end
    xline(0,'--k');grid on;ylabel('mA');title(strrep(metric,'_',' '));legend('false-safe','matched control');
end
xlabel(tl,'Sample offset');title(tl,'Matched false-safe event windows');
end
function fig_model(M,model)
P=M(M.cohort=="ENGINEERING_PRIMARY_VALIDATION" & ismember(M.model,["B0",string(model)]),:);tl=tiledlayout(1,2);
nexttile;bar(categorical(P.model,P.model),100*P.false_safe_rate);ylabel('False-safe (%)');title('Held-out classification');grid on;
nexttile;bar(categorical(P.model,P.model),1e3*P.residual_rms_after);ylabel('Vector RMS (mA)');title('Prediction residual');grid on;
title(tl,"B0 vs offline "+model+" correction");
end
function fig_case(K)
P=K(K.model=="6+12" & K.evidence_role=="ENGINEERING_PRIMARY",:);bar(categorical(P.case_id,P.case_id),100*P.false_safe_relative_reduction);
yline(20,'--r','20% gate');ylabel('Relative FS reduction (%)');title('Held-out 6+12 false-safe change by case');grid on;xtickangle(35);
end
function fig_train_validation(R)
P=R(R.evidence_role=="ENGINEERING_PRIMARY" & R.axis=="d",:);tl=tiledlayout(2,1,'TileSpacing','compact');
for order=[6 12]
    nexttile;Q=P(P.order==order,:);x=1:height(Q);plot(x,1e3*Q.calibration_amplitude,'o-');hold on;plot(x,1e3*Q.validation_amplitude,'s-');grid on;
    ylabel('mA');title(sprintf('%dth order',order));xticks(x);xticklabels(strrep(Q.case_id,'_',' '));xtickangle(30);
end
legend('calibration','held-out validation');title(tl,'Cycle-isolated amplitude comparison');
end
function fig_range(T)
ranges=["normal","reasonable_extension","stress_test"];fs=zeros(3,1);rr=fs;
for k=1:3,m=T.range_class==ranges(k);fs(k)=mean(T.false_safe(m));rr(k)=rms(T.residual_magnitude(m));end
tl=tiledlayout(1,2);nexttile;bar(categorical(ranges,ranges),100*fs);ylabel('False-safe (%)');grid on;title('All registered samples');
nexttile;bar(categorical(ranges,ranges),1e3*rr);ylabel('Residual RMS (mA)');grid on;title('Stress is secondary');title(tl,'Normal/reasonable-extension/stress comparison');
end
function T=read_forced(path,names)
o=detectImportOptions(path,'TextType','string');o=setvartype(o,cellstr(names),'string');T=readtable(path,o);
end
