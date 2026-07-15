function files = generate_plots(project,data)
%GENERATE_PLOTS Produce the auditable A0--A4 feasibility-control figures.
%
% files = zhou_feasibility.generate_plots(project,data) uses the in-memory
% campaign data returned by run_campaign.  The second input is optional;
% when it is omitted the latest campaign_data.mat (or the root/result CSV
% files) is loaded.  project may also be the project root path.  Failed
% simulations are labelled FAIL and missing metrics remain NaN/N/A; they
% are never replaced by zero.

if nargin<1 || isempty(project)
    root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
    project=struct('root',root);
elseif ischar(project) || isstring(project)
    project=struct('root',char(project));
end
if ~isfield(project,'root')
    error('ZhouFeasibility:PlotProject','project.root is required.');
end
root=char(project.root);
if nargin<2 || isempty(data)
    data=load_campaign_or_csv(root);
end
data=complete_tables_from_csv(data,root);
run_id=resolve_run_id(project,data,root);

out=struct();
out.A0=fullfile(root,'plots','A0_frozen_regression');
out.A1=fullfile(root,'plots','A1_original_failure');
out.A2=fullfile(root,'plots','A2_six_condition');
out.A3=fullfile(root,'plots','A3_boundary');
out.A4=fullfile(root,'plots','A4_negative_id');
names=fieldnames(out);
for k=1:numel(names)
    if ~isfolder(out.(names{k})),mkdir(out.(names{k}));end
end

strategies=["original_zhou","radial_hex_projection","proposed_feasibility_aware"];
display_names=["S0 original Zhou","S1 radial projection","S2+S3 proposed"];
traces=cell(1,3);
for k=1:3
    traces{k}=get_a1_trace(data,root,run_id,strategies(k));
end
original=traces{1}; radial=traces{2}; proposed=traces{3};
files=strings(0,1);

%% A0: preserve and expose the frozen illegal event.
fail_index=first_failure_index(original);
selected_fail_s=original.t_s(fail_index);
applied_fail_s=infer_applied_failure_time(original,selected_fail_s);

f=new_figure();
plot(1e3*original.t_s,original.d0,'LineWidth',1.7);hold on;
plot(1e3*original.t_s,original.d1,'LineWidth',1.4);
plot(1e3*original.t_s,original.d2,'LineWidth',1.4);
yline(0,'k--','0 boundary','LineWidth',1.0);
xline(1e3*selected_fail_s,'r--','selected FAIL','LineWidth',1.3, ...
    'LabelVerticalAlignment','bottom');
xline(1e3*applied_fail_s,'r:','applied FAIL','LineWidth',1.3);
mark_failure(1e3*selected_fail_s,original.d0(fail_index),'FAIL');
xlabel('Time (ms)');ylabel('Selected duty');
title('A0 frozen P1 failure: Case 3 duties');
legend('d_0','d_1','d_2','Location','best');grid on;
xlim(failure_window(original.t_s,selected_fail_s));
files(end+1)=save_png(f,fullfile(out.A0,'A0_01_failure_duties.png')); %#ok<AGROW>

f=new_figure();
plot(1e3*original.t_s,original.voltage_utilization_ratio,'b','LineWidth',1.7);hold on;
yline(1,'k--','hexagon boundary','LineWidth',1.1);
xline(1e3*selected_fail_s,'r--','selected FAIL','LineWidth',1.3);
mark_failure(1e3*selected_fail_s,original.voltage_utilization_ratio(fail_index),'FAIL');
xlabel('Time (ms)');ylabel('Hexagon utilization ratio');
title('A0 frozen P1 failure: voltage feasibility');grid on;
xlim(failure_window(original.t_s,selected_fail_s));
files(end+1)=save_png(f,fullfile(out.A0,'A0_02_failure_voltage_utilization.png')); %#ok<AGROW>

f=new_figure([100 100 900 760]);hold on;axis equal;grid on;
[H,R,uc]=failure_geometry(original,fail_index);
patch(H(:,1),H(:,2),[0.78 0.88 1.00],'FaceAlpha',0.25, ...
    'EdgeColor',[0.05 0.25 0.65],'LineWidth',1.8,'DisplayName','H: inverter hexagon');
patch(R(:,1),R(:,2),[0.98 0.86 0.35],'FaceAlpha',0.18, ...
    'EdgeColor',[0.75 0.45 0.02],'LineWidth',1.8,'DisplayName','R: J_d/J_q rectangle');
plot(uc(1),uc(2),'rx','MarkerSize',12,'LineWidth',2.4,'DisplayName','u_c: original FAIL');
ur=trace_point_at(radial,selected_fail_s);
us=trace_point_at(proposed,selected_fail_s);
if all(isfinite(ur))
    plot([0 ur(1)],[0 ur(2)],'--','Color',[0.45 0.45 0.45],'HandleVisibility','off');
    plot(ur(1),ur(2),'o','Color',[0.35 0.35 0.35],'MarkerFaceColor',[0.75 0.75 0.75], ...
        'MarkerSize',8,'DisplayName','S1 radial target');
end
if all(isfinite(us))
    plot([uc(1) us(1)],[uc(2) us(2)],'m--','LineWidth',1.2,'HandleVisibility','off');
    plot(us(1),us(2),'mp','MarkerFaceColor','m','MarkerSize',11, ...
        'DisplayName','S2 nearest R \cap H target');
end
plot(0,0,'k.','MarkerSize',12,'HandleVisibility','off');
xlabel('u_\alpha (V)');ylabel('u_\beta (V)');
title(sprintf('A0 failure geometry at selected t = %.1f ms',1e3*selected_fail_s));
legend('Location','bestoutside');
annotation(f,'textbox',[.13 .01 .76 .055],'String', ...
    'FAIL is retained: u_c lies outside H; S1 and S2+S3 targets are plotted independently.', ...
    'EdgeColor','none','HorizontalAlignment','center','Color',[0.65 0 0]);
files(end+1)=save_png(f,fullfile(out.A0,'A0_03_failure_R_H_S2_radial_geometry.png')); %#ok<AGROW>

%% A1: time-domain comparison and scalar engineering metrics.
f=new_figure([100 100 1150 760]);
for axis_index=1:2
    subplot(2,1,axis_index);hold on;grid on;
    for k=1:3
        T=traces{k};
        if axis_index==1
            plot(1e3*T.t_s,T.id_A,'LineWidth',1.25,'DisplayName',display_names(k));
        else
            plot(1e3*T.t_s,T.iq_A,'LineWidth',1.25,'DisplayName',display_names(k));
        end
        if trace_failed(T)
            y=ternary(axis_index==1,T.id_A(end),T.iq_A(end));
            text(1e3*T.t_s(end),y,'  FAIL','Color',[0.75 0 0],'FontWeight','bold');
        end
    end
    Tref=proposed;
    if axis_index==1
        plot(1e3*Tref.t_s,Tref.id_ref_A,'k--','LineWidth',1.1,'DisplayName','reference');
        ylabel('i_d (A)');
    else
        plot(1e3*Tref.t_s,Tref.iq_ref_A,'k--','LineWidth',1.1,'DisplayName','reference');
        ylabel('i_q (A)');xlabel('Time (ms)');
    end
end
subplot(2,1,1);title('A1 current tracking: all strategies, including the truncated FAIL trace');
legend('Location','bestoutside');
files(end+1)=save_png(f,fullfile(out.A1,'A1_01_three_strategy_currents.png')); %#ok<AGROW>

f=new_figure();
yyaxis left;
stairs(1e3*proposed.t_s,proposed.fallback_used,'LineWidth',1.3);
ylabel('Fallback active (0/1)');ylim([-0.05 1.15]);
yyaxis right;
plot(1e3*proposed.t_s,proposed.fallback_consecutive_cycles,'LineWidth',1.4);
ylabel('Consecutive fallback cycles');xlabel('Time (ms)');grid on;
title('A1 proposed method: fallback activity and persistence');
files(end+1)=save_png(f,fullfile(out.A1,'A1_02_fallback_activity.png')); %#ok<AGROW>

A1=rows_by_strategy(data.A1,strategies);
files(end+1)=plot_metric(A1,'steady_thd_percent','Phase-current THD (%)', ...
    'A1 phase-current THD (FAIL is not averaged or replaced)',display_names, ...
    fullfile(out.A1,'A1_03_phase_current_THD.png'),true); %#ok<AGROW>
files(end+1)=plot_metric(A1,'torque_ripple_Nm','Torque ripple, std (N m)', ...
    'A1 steady torque ripple (FAIL remains unavailable)',display_names, ...
    fullfile(out.A1,'A1_04_torque_ripple.png'),true); %#ok<AGROW>
files(end+1)=plot_metric(A1,'switching_actions','Switching actions over completed run', ...
    'A1 switching actions (truncated FAIL is excluded explicitly)',display_names, ...
    fullfile(out.A1,'A1_05_switching_actions.png'),true); %#ok<AGROW>

f=new_figure();
E=1e6*[A1.execution_time_average_s,A1.execution_time_p95_s,A1.execution_time_max_s];
b=bar(1:3,E,'grouped');hold on;grid on; %#ok<NASGU>
set(gca,'XTick',1:3,'XTickLabel',display_names,'XTickLabelRotation',15);
ylabel('Controller execution time (\mus)');
title('A1 per-cycle execution time (S0 measurements are from its partial FAIL trace)');
legend('average','p95','maximum','Location','best');
st=run_success(A1);
for k=1:3
    if ~st(k)
        y=max(E(k,:),[],'omitnan');if isempty(y)||~isfinite(y),y=0;end
        text(k,y,'FAIL partial','Color',[0.75 0 0],'FontWeight','bold', ...
            'HorizontalAlignment','center','VerticalAlignment','bottom');
    end
end
files(end+1)=save_png(f,fullfile(out.A1,'A1_06_execution_time.png')); %#ok<AGROW>

%% A2: no favorable averaging; every strategy/condition is visible.
f=new_figure([100 100 1050 800]);
[M,row_labels]=a2_status_matrix(data.A2,strategies);
draw_status_matrix(M,row_labels,display_names, ...
    'A2 six-condition P0/P1 completion and legality matrix');
files(end+1)=save_png(f,fullfile(out.A2,'A2_01_all_condition_success_matrix.png')); %#ok<AGROW>

%% A3: boundary revalidation, command modification and legality.
proposed_A3=data.A3(string(data.A3.strategy)==strategies(3),:);
[M,vdcs,ramps]=a3_grid(proposed_A3,'modified_command_fraction');
f=new_figure([100 100 960 650]);
draw_numeric_matrix(M,string(compose('%.4g',vdcs)),string(compose('%.5g',1e3*ramps)), ...
    'V_{dc} (V)','Ramp (ms)','A3 proposed command-modification fraction','%.3f');
files(end+1)=save_png(f,fullfile(out.A3,'A3_01_modified_command_fraction.png')); %#ok<AGROW>

f=new_figure([100 100 1280 520]);
for k=1:3
    subplot(1,3,k);
    Tk=data.A3(string(data.A3.strategy)==strategies(k),:);
    [Mk,vdcs,ramps]=a3_status_grid(Tk);
    draw_status_matrix(Mk,string(compose('%.5g ms',1e3*ramps)), ...
        string(compose('%.4g V',vdcs)),display_names(k));
end
sgtitle('A3 V_{dc}-ramp legality: PASS/FAIL shown for every strategy');
files(end+1)=save_png(f,fullfile(out.A3,'A3_02_Vdc_ramp_legality.png')); %#ok<AGROW>

%% A4: negative-id admission remains a probe, not an MTPA claim.
f=new_figure([100 100 1080 520]);
for k=[1 3]
    subplot(1,2,1+(k==3));
    Tk=data.A4(string(data.A4.strategy)==strategies(k),:);
    [Mk,speeds,ids]=a4_grid(Tk,'status');
    draw_status_matrix(Mk,string(compose('i_d = %g A',ids)), ...
        string(compose('%g rpm',speeds)),display_names(k));
end
sgtitle('A4 negative-i_d admission: 0.2 s completion and command legality');
files(end+1)=save_png(f,fullfile(out.A4,'A4_01_negative_id_admission.png')); %#ok<AGROW>

Tk=data.A4(string(data.A4.strategy)==strategies(3),:);
[M,speeds,ids]=a4_grid(Tk,'fallback_fraction');
f=new_figure([100 100 900 650]);
draw_numeric_matrix(M,string(compose('%g rpm',speeds)),string(compose('%g',ids)), ...
    'Speed','i_d reference (A)','A4 proposed fallback fraction','%.3f');
files(end+1)=save_png(f,fullfile(out.A4,'A4_02_negative_id_fallback_fraction.png')); %#ok<AGROW>

fprintf('Generated %d independent PNG figures under %s\n',numel(files),fullfile(root,'plots'));
end

function data=load_campaign_or_csv(root)
listing=dir(fullfile(root,'results','summary','*','campaign_data.mat'));
if ~isempty(listing)
    [~,order]=sort([listing.datenum],'descend');
    loaded=load(fullfile(listing(order(1)).folder,listing(order(1)).name),'data');
    data=loaded.data;return
end
data=struct();
end

function data=complete_tables_from_csv(data,root)
mapping={ 'A1',fullfile(root,'BASELINE_COMPARISON.csv'); ...
    'A2',fullfile(root,'SIX_CONDITION_COMPARISON.csv'); ...
    'A4',fullfile(root,'NEGATIVE_ID_ADMISSION.csv')};
for k=1:size(mapping,1)
    field=mapping{k,1};path=mapping{k,2};
    if (~isfield(data,field)||isempty(data.(field))) && isfile(path)
        data.(field)=readtable(path,'TextType','string');
    end
end
if ~isfield(data,'A3')||isempty(data.A3)
    f=newest_file(fullfile(root,'results','A3_boundary','*','Vdc_ramp_boundary_comparison.csv'));
    if strlength(f)>0,data.A3=readtable(f,'TextType','string');end
end
required={'A1','A2','A3','A4'};
for k=1:numel(required)
    if ~isfield(data,required{k})||isempty(data.(required{k}))
        error('ZhouFeasibility:PlotData','Missing %s campaign table.',required{k});
    end
end
data.A1=augment_design_columns(data.A1,'A1');
data.A2=augment_design_columns(data.A2,'A2');
data.A3=augment_design_columns(data.A3,'A3');
data.A4=augment_design_columns(data.A4,'A4');
end

function T=augment_design_columns(T,experiment)
% Older completed campaign files encoded design coordinates only in the
% auditable scenario name.  Recover those coordinates without inventing
% values, so the plotting layer accepts both schema generations.
n=height(T);scenario=string(T.scenario);
speed=NaN(n,1);id=NaN(n,1);iq=NaN(n,1);
for k=1:n
    if experiment=="A2"
        token=regexp(char(scenario(k)),'A2_([-+0-9.]+)rpm_([-+0-9.]+)A_(P[01])_','tokens','once');
        if ~isempty(token),speed(k)=str2double(token{1});iq(k)=str2double(token{2});end
    elseif experiment=="A4"
        token=regexp(char(scenario(k)),'A4_([-+0-9.]+)rpm_id([-+0-9.]+)_iq([-+0-9.eE]+)_','tokens','once');
        if ~isempty(token)
            speed(k)=str2double(token{1});id(k)=str2double(token{2});iq(k)=str2double(token{3});
        end
    elseif experiment=="A1"
        token=regexp(char(scenario(k)),'(?:A0|A1)_P1_([-+0-9.]+)rpm_([-+0-9.]+)A','tokens','once');
        if ~isempty(token),speed(k)=str2double(token{1});id(k)=0;iq(k)=str2double(token{2});end
    end
end
if ~ismember('speed_rpm',T.Properties.VariableNames),T=addvars(T,speed,'After','scenario','NewVariableNames','speed_rpm');end
if ~ismember('id_ref_A',T.Properties.VariableNames),T=addvars(T,id,'After','speed_rpm','NewVariableNames','id_ref_A');end
if ~ismember('iq_ref_A',T.Properties.VariableNames),T=addvars(T,iq,'After','id_ref_A','NewVariableNames','iq_ref_A');end
end

function run_id=resolve_run_id(project,data,root)
run_id="";
if isfield(data,'A1') && ismember('run_id',data.A1.Properties.VariableNames)
    run_id=string(data.A1.run_id(1));
end
if strlength(run_id)==0 && isfield(project,'run_id'),run_id=string(project.run_id);end
if strlength(run_id)==0
    f=newest_file(fullfile(root,'results','A1_original_failure','*','strategy_summary.csv'));
    if strlength(f)>0,run_id=string(get_last_folder(char(f)));end
end
end

function T=get_a1_trace(data,root,run_id,strategy)
T=table();
if isfield(data,'A1_traces')
    C=data.A1_traces;
    if iscell(C)&&numel(C)==1&&iscell(C{1}),C=C{1};end
    if ~iscell(C),C=num2cell(C);end
    for k=1:numel(C)
        s=C{k};
        if isstruct(s)&&isfield(s,'summary')&&isfield(s,'trace') && ...
                ismember('strategy',s.summary.Properties.VariableNames) && ...
                string(s.summary.strategy(1))==strategy
            T=s.trace;return
        end
    end
end
candidate=fullfile(root,'results','A1_original_failure',char(run_id),char(strategy+'_trace.csv'));
if ~isfile(candidate)
    candidate=char(newest_file(fullfile(root,'results','A1_original_failure','*',char(strategy+'_trace.csv'))));
end
if ~isfile(candidate) && strategy=="original_zhou"
    candidate=char(newest_file(fullfile(root,'results','A0_frozen_regression','*','P1_failure_trace.csv')));
end
if ~isfile(candidate),error('ZhouFeasibility:PlotTrace','Missing A1 trace for %s.',strategy);end
T=readtable(candidate,'TextType','string');
end

function index=first_failure_index(T)
index=[];
if ismember('selected_legal',T.Properties.VariableNames)
    index=find(~logical(T.selected_legal),1,'first');
end
if isempty(index)&&ismember('d0',T.Properties.VariableNames),index=find(T.d0<0,1,'first');end
if isempty(index),[~,index]=min(T.d0);end
end

function t=infer_applied_failure_time(T,selected_t)
t=NaN;
if ismember('applied_legal',T.Properties.VariableNames)
    k=find(~logical(T.applied_legal),1,'first');if ~isempty(k),t=T.t_s(k);end
end
if ~isfinite(t)
    dt=median(diff(T.t_s),'omitnan');t=selected_t+dt;
end
end

function limits=failure_window(t,t0)
lower=max(min(1e3*t),1e3*t0-1.5);upper=min(max(1e3*t),1e3*t0+0.3);
if upper<=lower,lower=min(1e3*t);upper=max(1e3*t);end
limits=[lower upper];
end

function [H,R,uc]=failure_geometry(T,k)
radius=T.active_vector_magnitude_V(k);
angles=(0:6)'*pi/3;H=radius*[cos(angles),sin(angles)];
center=[T.rectangle_center_alpha_V(k),T.rectangle_center_beta_V(k)];
hd=T.rectangle_half_d_V(k);hq=T.rectangle_half_q_V(k);theta=T.geometry_theta_rad(k);
local=[-hd -hq;hd -hq;hd hq;-hd hq;-hd -hq];
Q=[cos(theta),-sin(theta);sin(theta),cos(theta)];
R=local*Q.'+center;
uc=[T.reference_alpha_V(k),T.reference_beta_V(k)];
end

function point=trace_point_at(T,t)
[~,k]=min(abs(T.t_s-t));point=[T.reference_alpha_V(k),T.reference_beta_V(k)];
end

function failed=trace_failed(T)
failed=any(~logical(T.selected_legal))||any(~logical(T.applied_legal))||T.t_s(end)<0.1998;
end

function T=rows_by_strategy(T,strategies)
indices=NaN(numel(strategies),1);
for k=1:numel(strategies),indices(k)=find(string(T.strategy)==strategies(k),1,'first');end
if any(isnan(indices)),error('ZhouFeasibility:PlotSummary','A1 strategy row missing.');end
T=T(indices,:);
end

function path=plot_metric(T,field,ylabel_text,title_text,labels,path,hide_failed)
values=T.(field);success=run_success(T);shown=values;
if hide_failed,shown(~success)=NaN;end
f=new_figure();bar(1:numel(shown),shown,0.65,'FaceColor',[0.18 0.48 0.78]);hold on;grid on;
set(gca,'XTick',1:numel(shown),'XTickLabel',labels,'XTickLabelRotation',15);
ylabel(ylabel_text);title(title_text);
finite_values=shown(isfinite(shown));if isempty(finite_values),top=1;else,top=max(finite_values);if top<=0,top=1;end,end
ylim_current=ylim;top=max(top,ylim_current(2));
for k=1:numel(shown)
    if ~success(k)
        text(k,0.92*top,'FAIL','Color',[0.75 0 0],'FontWeight','bold','HorizontalAlignment','center');
    elseif ~isfinite(shown(k))
        text(k,0.50*top,'N/A','Color',[0.35 0.35 0.35],'HorizontalAlignment','center');
    end
end
path=save_png(f,path);
end

function success=run_success(T)
success=logical(T.completed_0p2s)&T.illegal_command_count==0&T.negative_duration_count==0;
end

function [M,labels]=a2_status_matrix(T,strategies)
keys=string(compose('%g|%g|%s',T.speed_rpm,T.iq_ref_A,string(T.motor_model)));
[unique_keys,first]=unique(keys,'stable');
labels=string(compose('%g rpm / %g A / %s',T.speed_rpm(first),T.iq_ref_A(first),string(T.motor_model(first))));
M=NaN(numel(unique_keys),numel(strategies));
for i=1:numel(unique_keys)
    for j=1:numel(strategies)
        k=find(keys==unique_keys(i)&string(T.strategy)==strategies(j),1,'first');
        if ~isempty(k),M(i,j)=run_success(T(k,:));end
    end
end
end

function [M,vdcs,ramps]=a3_grid(T,field)
vdcs=sort(unique(T.dc_bus_V));ramps=sort(unique(T.reference_ramp_s));
M=NaN(numel(ramps),numel(vdcs));
for i=1:numel(ramps)
    for j=1:numel(vdcs)
        k=find(abs(T.reference_ramp_s-ramps(i))<1e-12 & abs(T.dc_bus_V-vdcs(j))<1e-12,1);
        if ~isempty(k),M(i,j)=T.(field)(k);end
    end
end
end

function [M,vdcs,ramps]=a3_status_grid(T)
[M,vdcs,ramps]=a3_grid(T,'completed_0p2s');
for i=1:numel(ramps)
    for j=1:numel(vdcs)
        k=find(abs(T.reference_ramp_s-ramps(i))<1e-12 & abs(T.dc_bus_V-vdcs(j))<1e-12,1);
        if ~isempty(k),M(i,j)=run_success(T(k,:));end
    end
end
end

function [M,speeds,ids]=a4_grid(T,field)
speeds=sort(unique(T.speed_rpm));ids=sort(unique(T.id_ref_A));
M=NaN(numel(ids),numel(speeds));
for i=1:numel(ids)
    for j=1:numel(speeds)
        k=find(abs(T.id_ref_A-ids(i))<1e-12 & abs(T.speed_rpm-speeds(j))<1e-12,1);
        if ~isempty(k)
            if strcmp(field,'status'),M(i,j)=run_success(T(k,:));else,M(i,j)=T.(field)(k);end
        end
    end
end
end

function draw_status_matrix(M,row_labels,column_labels,title_text)
imagesc(M,'AlphaData',isfinite(M));axis tight;
colormap(gca,[0.85 0.20 0.16;0.20 0.65 0.32]);caxis([0 1]);
set(gca,'Color',[0.88 0.88 0.88],'XTick',1:numel(column_labels), ...
    'XTickLabel',column_labels,'YTick',1:numel(row_labels),'YTickLabel',row_labels, ...
    'XTickLabelRotation',15);
for i=1:size(M,1)
    for j=1:size(M,2)
        if isnan(M(i,j)),label='N/A';color=[0.2 0.2 0.2];
        elseif M(i,j)>0.5,label='PASS';color='w';
        else,label='FAIL';color='w';end
        text(j,i,label,'HorizontalAlignment','center','Color',color,'FontWeight','bold');
    end
end
title(title_text,'Interpreter','none');
end

function draw_numeric_matrix(M,column_labels,row_labels,xlabel_text,ylabel_text,title_text,format)
imagesc(M,'AlphaData',isfinite(M));axis tight;colorbar;
colormap(gca,parula(256));set(gca,'Color',[0.88 0.88 0.88], ...
    'XTick',1:numel(column_labels),'XTickLabel',column_labels, ...
    'YTick',1:numel(row_labels),'YTickLabel',row_labels);
xlabel(xlabel_text);ylabel(ylabel_text);title(title_text,'Interpreter','none');
for i=1:size(M,1)
    for j=1:size(M,2)
        if isfinite(M(i,j)),label=sprintf(format,M(i,j));else,label='N/A';end
        text(j,i,label,'HorizontalAlignment','center','Color','k','FontWeight','bold');
    end
end
end

function mark_failure(x,y,label)
if isfinite(x)&&isfinite(y)
    plot(x,y,'rx','MarkerSize',11,'LineWidth',2.2,'HandleVisibility','off');
    text(x,y,['  ' label],'Color',[0.75 0 0],'FontWeight','bold', ...
        'VerticalAlignment','bottom');
end
end

function f=new_figure(position)
if nargin<1,position=[100 100 1080 680];end
f=figure('Visible','off','Color','w','Position',position);
set(f,'InvertHardcopy','off');
end

function path=save_png(f,path)
exportgraphics(f,path,'Resolution',180,'BackgroundColor','white');close(f);path=string(path);
end

function result=ternary(condition,a,b)
if condition,result=a;else,result=b;end
end

function path=newest_file(pattern)
listing=dir(pattern);path="";if isempty(listing),return;end
[~,order]=sort([listing.datenum],'descend');path=string(fullfile(listing(order(1)).folder,listing(order(1)).name));
end

function folder=get_last_folder(path)
folder=fileparts(path);[~,folder]=fileparts(folder);
end
