function manifest=generate_minimal_figures(project)
%GENERATE_MINIMAL_FIGURES Gate-level figures only; no full-campaign claims.
M=readtable(fullfile(project.dirs.summary,'minimal_method_metrics.csv'),'TextType','string');
figdir=fullfile(project.dirs.figures,'minimal');if ~isfolder(figdir),mkdir(figdir);end
files=strings(0,1);descriptions=strings(0,1);
make_bar(100*M.false_safe_rate,'False-safe (%)','Five-case ENGINEERING_PRIMARY', ...
    '01_false_safe_comparison.png');
make_bar(100*M.false_alarm_rate,'False-alarm (%)','Five-case ENGINEERING_PRIMARY', ...
    '02_false_alarm_comparison.png');
make_bar(M.vector_rms_A,'Prediction vector RMS (A)','Five-case ENGINEERING_PRIMARY', ...
    '03_prediction_rms_comparison.png');
q0=load(fullfile(project.dirs.cache,'minimal_B0_C07_known_false_safe_r1.mat'),'simulation');
qp=load(fullfile(project.dirs.cache,'minimal_P_C07_known_false_safe_r1.mat'),'simulation');
f=figure('Visible','off','Color','w');plot(q0.simulation.trace.time_s*1e3,q0.simulation.trace.iq,'LineWidth',1);hold on;
plot(qp.simulation.trace.time_s*1e3,qp.simulation.trace.iq,'LineWidth',1);plot(q0.simulation.trace.time_s*1e3,q0.simulation.trace.iq_ref,'k--');
xlabel('Time (ms)');ylabel('i_q (A)');title('C07 known false-safe: early-termination evidence');legend('B0','P','reference','Location','best');grid on;
save_fig(f,'04_known_false_safe_time_domain.png','C07 B0/P time-domain and termination divergence');
q=load(fullfile(project.dirs.cache,'minimal_P_P08_opposed_20pct_r1.mat'),'simulation');T=q.simulation.trace;
f=figure('Visible','off','Color','w');plot(T.time_s*1e3,T.alpha_d,'LineWidth',1);hold on;plot(T.time_s*1e3,T.alpha_q,'LineWidth',1);
xlabel('Time (ms)');ylabel('alpha (A/(V s))');title('P08: P estimator states');legend('alpha_d','alpha_q');grid on;
save_fig(f,'05_alpha_trajectories.png','P08 alpha d/q trajectories');
files=files(:);descriptions=descriptions(:);
manifest=table(files,descriptions,repmat("MINIMAL_GATE",numel(files),1), ...
    'VariableNames',{'file','description','scope'});writetable(manifest,fullfile(figdir,'figure_manifest.csv'));

    function make_bar(y,ylab,ttl,name)
        f=figure('Visible','off','Color','w');bar(categorical(M.method),y);ylabel(ylab);title(ttl);grid on;
        save_fig(f,name,ttl+" "+ylab);
    end
    function save_fig(f,name,description)
        exportgraphics(f,fullfile(figdir,name),'Resolution',160);close(f);
        files(end+1)=string(fullfile(figdir,name));descriptions(end+1)=description;
    end
end
