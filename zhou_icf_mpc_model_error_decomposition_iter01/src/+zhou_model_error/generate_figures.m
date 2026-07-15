function manifest=generate_figures(project,T,S,C)
%GENERATE_FIGURES Emit the fifteen preregistered audit figure categories.
set(groot,'defaultFigureVisible',char(project.model_error.figure_visible), ...
    'defaultTextInterpreter','none','defaultAxesTickLabelInterpreter','none','defaultLegendInterpreter','none');out=project.dirs.figures;
spec={ ...
"01_predictors_vs_actual.png",@()prediction_actual(T); ...
"02_residual_rms_by_predictor.png",@()rms_bars(S.predictor_metrics); ...
"03_false_safe_by_predictor.png",@()false_safe_bars(S.predictor_metrics); ...
"04_F_replacement_time_domain.png",@()F_time(T); ...
"05_alpha_replacement_time_domain.png",@()alpha_time(T); ...
"06_P3_P4_P5_error_chain.png",@()structure_time(T); ...
"07_candidate_top1_flip_matrix.png",@()flip_matrix(S.candidate,"top1_flip_vs_P0_rate","Top-1 flip rate vs P0"); ...
"08_candidate_mode_flip_matrix.png",@()flip_matrix(S.candidate,"mode_flip_vs_P0_rate","Mode flip rate vs P0"); ...
"09_residual_vs_delta_F.png",@()deltaF_scatter(T); ...
"10_residual_vs_alpha_error.png",@()alpha_scatter(T); ...
"11_residual_vs_state.png",@()state_scatter(T); ...
"12_residual_spectrum.png",@()spectrum_plot(S.spectrum); ...
"13_S2_residual_comparison.png",@()S2_plot(T); ...
"14_parameter_over_under_asymmetry.png",@()parameter_asymmetry(S.predictor_metrics); ...
"15_case_error_source_share.png",@()source_share(S.contribution)};
rows=cell(size(spec,1),4);
for k=1:size(spec,1)
    file=fullfile(out,spec{k,1});f=figure('Color','w','Position',[100 100 1250 720]);
    try,spec{k,2}();grid_on_axes(f);exportgraphics(f,file,'Resolution',160);ok=true;message="";
    catch ME,ok=false;message=string(ME.message);close(f);rethrow(ME);end
    close(f);rows(k,:)={k,string(spec{k,1}),ok,message};
end
manifest=cell2table(rows,'VariableNames',{'figure_number','file_name','generated','message'});
writetable(manifest,fullfile(out,'figure_manifest.csv'));
end

function prediction_actual(T)
X=pick_case(T,["C09_S2_boundary","C01_nominal_100rpm_10A"]);ix=tail_indices(X,350);
t=1e3*X.time_s(ix);names=["P0","P1","P2a","P2b","P2c","P3a","P3b","P3c","P4","P5"];
tiledlayout(2,1,'TileSpacing','compact');nexttile;plot(t,X.id_actual(ix),'k','LineWidth',1.6);hold on
for p=names,plot(t,X.("id_pred_"+p)(ix),'LineWidth',.9);end
ylabel('i_d (A)');title(X.case_id(1)+": k+2 predictions vs actual");legend(["actual",names],'Location','eastoutside');
nexttile;plot(t,X.iq_actual(ix),'k','LineWidth',1.6);hold on
for p=names,plot(t,X.("iq_pred_"+p)(ix),'LineWidth',.9);end
ylabel('i_q (A)');xlabel('prediction origin time k (ms)');
end

function rms_bars(M)
X=M(M.cohort=="REPRODUCTION_ALL",:);bar(categorical(X.predictor,X.predictor),X.vector_rms_A);ylabel('vector residual RMS (A)');title('P0-P5 residual RMS');
end

function false_safe_bars(M)
X=M(M.cohort=="REPRODUCTION_ALL",:);bar(categorical(X.predictor,X.predictor),100*X.false_safe_joint_rate);ylabel('joint false-safe (%)');title('Independent-current-constraint false-safe');
end

function F_time(T)
X=pick_case(T,["C09_S2_boundary","C07_known_false_safe"]);ix=tail_indices(X,450);t=1e3*X.time_s(ix);
plot(t,hypot(X.ed_P0(ix),X.eq_P0(ix)),'LineWidth',1.2);hold on;plot(t,hypot(X.ed_P2a(ix),X.eq_P2a(ix)),'LineWidth',1.2);plot(t,hypot(X.ed_P2b(ix),X.eq_P2b(ix)),'LineWidth',1.2);
xlabel('prediction origin time k (ms)');ylabel('||e||_2 (A)');title(X.case_id(1)+": F substitution");legend('P0 original F','P2a previous-period F','P2b physical F');
end

function alpha_time(T)
X=pick_case(T,["P06_controller_high_L","P08_opposed_20pct"]);ix=tail_indices(X,450);t=1e3*X.time_s(ix);
plot(t,hypot(X.ed_P0(ix),X.eq_P0(ix)),'LineWidth',1.2);hold on;plot(t,hypot(X.ed_P1(ix),X.eq_P1(ix)),'LineWidth',1.2);
xlabel('prediction origin time k (ms)');ylabel('||e||_2 (A)');title(X.case_id(1)+": alpha substitution");legend('P0 original alpha','P1 oracle alpha');
end

function structure_time(T)
X=pick_case(T,["D03_id_iq_step","D04_torque_ramp"]);ix=tail_indices(X,600);t=1e3*X.time_s(ix);
plot(t,hypot(X.ed_P3b(ix),X.eq_P3b(ix)),'LineWidth',1.2);hold on;plot(t,hypot(X.ed_P4(ix),X.eq_P4(ix)),'LineWidth',1.2);plot(t,hypot(X.ed_P5(ix),X.eq_P5(ix)),'k','LineWidth',1.2);
xlabel('prediction origin time k (ms)');ylabel('||e||_2 (A)');title(X.case_id(1)+": freezing/discretization chain");legend('P3b frozen physical F','P4 refreshed Euler','P5 RK4 plant');
end

function flip_matrix(C,field,titleText)
X=C(C.cohort_type=="case",:);cases=unique(X.cohort,'stable');predictors=unique(X.predictor,'stable');A=nan(numel(cases),numel(predictors));
for i=1:numel(cases),for j=1:numel(predictors),q=X.cohort==cases(i)&X.predictor==predictors(j);if any(q),A(i,j)=X.(field)(find(q,1));end,end,end
imagesc(100*A);colorbar;xticks(1:numel(predictors));xticklabels(predictors);yticks(1:numel(cases));yticklabels(cases);xlabel('predictor');ylabel('case');title(titleText+' (%)');
end

function deltaF_scatter(T)
ix=downsample_index(height(T),5000);tiledlayout(1,2,'TileSpacing','compact');nexttile;scatter(T.delta_Fd(ix),T.ed_P0(ix),7,T.speed_rpm(ix),'filled');xlabel('F_d estimate error (A/s)');ylabel('e_{P0,d} (A)');colorbar;title('d axis');
nexttile;scatter(T.delta_Fq(ix),T.eq_P0(ix),7,T.speed_rpm(ix),'filled');xlabel('F_q estimate error (A/s)');ylabel('e_{P0,q} (A)');colorbar;title('q axis');
end

function alpha_scatter(T)
ix=find(T.case_category=="parameter");ix=ix(downsample_index(numel(ix),5000));tiledlayout(1,2,'TileSpacing','compact');nexttile;scatter(T.alpha_d_error(ix),T.ed_P0(ix),7,T.speed_rpm(ix),'filled');xlabel('alpha_d error (A/(V s))');ylabel('e_{P0,d} (A)');colorbar;title('d axis');
nexttile;scatter(T.alpha_q_error(ix),T.eq_P0(ix),7,T.speed_rpm(ix),'filled');xlabel('alpha_q error (A/(V s))');ylabel('e_{P0,q} (A)');colorbar;title('q axis');
end

function state_scatter(T)
ix=downsample_index(height(T),6000);e=hypot(T.ed_P0(ix),T.eq_P0(ix));tiledlayout(1,3,'TileSpacing','compact');
nexttile;scatter(T.speed_rpm(ix),e,6,'filled');xlabel('speed (rpm)');ylabel('||e_{P0}|| (A)');
nexttile;scatter(T.id(ix),e,6,'filled');xlabel('i_d (A)');
nexttile;scatter(T.iq(ix),e,6,'filled');xlabel('i_q (A)');title('P0 residual versus operating state');
end

function spectrum_plot(S)
X=S(S.predictor=="P0"&S.spectrum_valid,:);cases=unique(X.case_id,'stable');A=nan(numel(cases),3);
for k=1:numel(cases),q=X.case_id==cases(k);A(k,:)=[mean(X.order1_rms_A(q),'omitnan'),mean(X.order6_rms_A(q),'omitnan'),mean(X.order12_rms_A(q),'omitnan')];end
bar(categorical(cases,cases),A);ylabel('residual harmonic RMS (A)');title('P0 coherent integer-cycle spectrum');legend('1x electrical','6x electrical','12x electrical');xtickangle(45);
end

function S2_plot(T)
names=["P0","P2b","P4","P5"];A=nan(numel(names),2);near=false(height(T),1);
for c=unique(T.case_id,'stable').',ix=find(T.case_id==c);hit=find(T.S2_triggered(ix));for h=hit.',near(ix(max(1,h-2):min(numel(ix),h+2)))=true;end,end
for k=1:numel(names),e=hypot(T.("ed_"+names(k)),T.("eq_"+names(k)));A(k,:)=[sqrt(mean(e(~near).^2,'omitnan')),sqrt(mean(e(near).^2,'omitnan'))];end
bar(categorical(names,names),A);ylabel('vector residual RMS (A)');title('S2-near versus other samples');legend('not S2-near','within +/-2 samples of S2');
end

function parameter_asymmetry(M)
X=M(M.cohort_type=="case"&ismember(M.cohort,["P06_controller_high_L","P07_controller_low_L"])&ismember(M.predictor,["P0","P1","P2b","P3b","P4"]),:);
pred=unique(X.predictor,'stable');A=nan(numel(pred),2);for k=1:numel(pred),A(k,1)=X.vector_rms_A(X.predictor==pred(k)&X.cohort=="P06_controller_high_L");A(k,2)=X.vector_rms_A(X.predictor==pred(k)&X.cohort=="P07_controller_low_L");end
bar(categorical(pred,pred),A);ylabel('vector residual RMS (A)');title('Parameter over/under-estimation asymmetry');legend('controller high L / actual 0.8x','controller low L / actual 1.2x');
end

function source_share(C)
X=C(C.cohort_type=="case",:);A=100*[X.F_share_of_explained,X.alpha_share_of_explained,X.structure_share_of_explained];
bar(categorical(X.cohort,X.cohort),A,'stacked');ylabel('signed share of P0-to-P5 explained MSE (%)');title('Error-source attribution by case');legend('F Shapley','alpha Shapley','freezing + discretization/structure');xtickangle(50);
end

function X=pick_case(T,preferences)
X=table();for p=preferences,if any(T.case_id==p),X=T(T.case_id==p,:);return,end,end;X=T(T.case_id==T.case_id(1),:);
end
function ix=tail_indices(T,n),ix=max(1,height(T)-n+1):height(T);end
function ix=downsample_index(n,target),if n<=target,ix=(1:n).';else,ix=unique(round(linspace(1,n,target))).';end,end
function grid_on_axes(f),a=findall(f,'Type','axes');for k=1:numel(a),grid(a(k),'on');box(a(k),'on');end,end
