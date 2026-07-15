function [detail,audit]=offline_candidate_audit(project,simulation,samples)
%OFFLINE_CANDIDATE_AUDIT Re-rank one declared diagnostic bank with P0--P5.
% This bank is not the native continuous Zhou geometry and never feeds the loop.
L=simulation.trace;N=height(samples);names=project.model_error.predictor_names;M=numel(names);
assert(N==height(L)-2,'ZhouModelError:CandidateAlignment');
rows=repmat(detail_template(),N*M,1);cursor=0;maxP0Gap=0;maxP5FinalGap=0;
convergenceChecks=0;convergenceFailures=0;convergenceMaxGap=0;
for k=1:N
    pending=trace_command(L,k,"applied",simulation.vectors,project.paper.Ts_s);
    [bank,finalIndex]=diagnostic_bank(L,k,simulation.vectors,project.paper.Ts_s,project.assumptions);
    [pred,timing]=evaluate_bank(project,simulation,samples,k,pending,bank);
    finalP0=reshape(pred(finalIndex,:,1),2,1);finalP5=reshape(pred(finalIndex,:,10),2,1);
    maxP0Gap=max(maxP0Gap,norm(finalP0-[samples.id_pred_P0(k);samples.iq_pred_P0(k)]));
    maxP5FinalGap=max(maxP5FinalGap,norm(finalP5-[samples.id_pred_P5(k);samples.iq_pred_P5(k)]));

    ranks=cell(M,1);top=nan(M,3);validMethod=false(M,1);
    scores=nan(numel(bank),M);feasible=false(numel(bank),M);
    reference=samples{k,{'id_ref','iq_ref'}};
    for p=1:M
        prediction=pred(:,:,p);J=(reference-prediction).^2;
        scores(:,p)=J(:,1)/.16+J(:,2)/.16;feasible(:,p)=all(J<=[.16,.16]+project.assumptions.constraint_tolerance_A2,2);
        ranks{p}=stable_order(scores(:,p),[bank.valid].');validMethod(p)=~isempty(ranks{p});
        if validMethod(p)
            q=ranks{p}(1:min(3,numel(ranks{p})));while numel(q)<3,q(end+1)=q(end);end %#ok<AGROW>
            top(p,:)=q(:).';
        end
    end
    if mod(k-1,max(1,round(N/20)))==0&&validMethod(10)
        accurate=evaluate_p5(project,simulation,L,k,pending,bank,project.model_error.integration_step_s);
        exactScore=sum((reference-accurate).^2/.16,2);exactOrder=stable_order(exactScore,[bank.valid].');
        convergenceChecks=convergenceChecks+1;
        convergenceFailures=convergenceFailures+(bank(exactOrder(1)).signature~=bank(top(10,1)).signature);
        convergenceMaxGap=max(convergenceMaxGap,max(vecnorm(accurate-pred(:,:,10),2,2),[],'omitnan'));
    end
    p0top=top(1,:);p5top=top(10,:);
    for p=1:M
        cursor=cursor+1;r=detail_template();r.case_id=samples.case_id(k);r.case_category=samples.case_category(k);
        r.range_class=samples.range_class(k);r.sample_index=samples.sample_index(k);r.time_s=samples.time_s(k);
        r.predictor=names(p);r.causality_class=causality(names(p));
        r.ranking_valid=~ismember(names(p),["P2c","P3c"]);r.ranking_invalid_reason="";
        if ~r.ranking_valid,r.ranking_invalid_reason="future-conditioned F; descriptive ranking only";end
        r.predictor_valid=validMethod(p);r.candidate_count=numel(bank);r.S2_triggered=samples.S2_triggered(k);
        r.candidate_bank_semantics="offline_diagnostic_candidate_bank_not_native_Zhou_candidates";
        r.evaluation_time_s=timing(p);r.actual_joint_pass=samples.actual_joint_pass(k);
        if validMethod(p)
            t=top(p,:);r.top1_name=bank(t(1)).name;r.top1_signature=bank(t(1)).signature;r.top1_mode=bank(t(1)).mode;
            r.top1_score=scores(t(1),p);r.top1_joint_feasible=feasible(t(1),p);
            r.top2_name=bank(t(2)).name;r.top2_signature=bank(t(2)).signature;
            r.top3_name=bank(t(3)).name;r.top3_signature=bank(t(3)).signature;
            r.top3_set_signature=signature_set(string({bank(t).signature}));
            r.top1_voltage_alpha_V=bank(t(1)).equivalent_ab(1);r.top1_voltage_beta_V=bank(t(1)).equivalent_ab(2);
            r.final_selected_signature=bank(finalIndex).signature;r.final_selected_mode=bank(finalIndex).mode;
            r.final_selected_rank=find(ranks{p}==finalIndex,1);r.final_selected_joint_feasible=feasible(finalIndex,p);
            r.final_selected_false_safe=r.final_selected_joint_feasible&&~r.actual_joint_pass;
            r.final_selected_false_alarm=~r.final_selected_joint_feasible&&r.actual_joint_pass;
            r.diagnostic_top1_voltage_changed=bank(t(1)).signature~=bank(finalIndex).signature;
            r.top1_flip_vs_P0=bank(t(1)).signature~=bank(p0top(1)).signature;
            r.top3_set_flip_vs_P0=r.top3_set_signature~=signature_set(string({bank(p0top).signature}));
            r.mode_flip_vs_P0=bank(t(1)).mode~=bank(p0top(1)).mode;
            r.feasibility_flip_vs_P0=feasible(finalIndex,p)~=feasible(finalIndex,1);
            r.top1_agrees_with_P5=bank(t(1)).signature==bank(p5top(1)).signature;
            r.mode_agrees_with_P5=bank(t(1)).mode==bank(p5top(1)).mode;
            r.top1_recovery_eligible=bank(p0top(1)).signature~=bank(p5top(1)).signature;
            r.top1_recovered=r.top1_recovery_eligible&&r.top1_agrees_with_P5;
            r.top1_new_error=bank(p0top(1)).signature==bank(p5top(1)).signature&&~r.top1_agrees_with_P5;
            r.mode_recovery_eligible=bank(p0top(1)).mode~=bank(p5top(1)).mode;
            r.mode_recovered=r.mode_recovery_eligible&&r.mode_agrees_with_P5;
            r.mode_new_error=bank(p0top(1)).mode==bank(p5top(1)).mode&&~r.mode_agrees_with_P5;
            r.top3_jaccard_vs_P5=jaccard(string({bank(t).signature}),string({bank(p5top).signature}));
        end
        if ~r.ranking_valid
            r.top1_agrees_with_P5=NaN;r.mode_agrees_with_P5=NaN;r.top1_recovery_eligible=NaN;
            r.top1_recovered=NaN;r.top1_new_error=NaN;r.mode_recovery_eligible=NaN;
            r.mode_recovered=NaN;r.mode_new_error=NaN;r.top3_jaccard_vs_P5=NaN;
        end
        rows(cursor)=r;
    end
end
detail=struct2table(rows(1:cursor),'AsArray',true);
assert(maxP0Gap<=project.model_error.predictor_tolerance_A,'ZhouModelError:CandidateP0Reproduction');
assert(maxP5FinalGap<=1e-8,'ZhouModelError:CandidateP5Approximation');
assert(convergenceFailures==0,'ZhouModelError:CandidateP5Convergence','10-us P5 ranking failed 2-us convergence.');
audit=struct('case_id',string(simulation.scenario.scenario_id),'sample_count',N, ...
    'P0_final_selected_max_gap_A',maxP0Gap,'P5_10us_final_selected_max_gap_A',maxP5FinalGap, ...
    'P5_convergence_checks',convergenceChecks,'P5_convergence_failures',convergenceFailures, ...
    'P5_10us_vs_2us_candidate_max_gap_A',convergenceMaxGap);
end

function [pred,timing]=evaluate_bank(project,simulation,S,k,pending,bank)
M=numel(project.model_error.predictor_names);C=numel(bank);pred=nan(C,2,M);timing=zeros(M,1);
Ts=project.paper.Ts_s;L=simulation.trace;theta=L.controller_theta_rad(k);omega=L.omega_e_rad_s(k);
uP=eq_voltage(pending,simulation.vectors,theta,omega,0,Ts);m=simulation.plant_motor;
a0=[S.alpha_d_original(k);S.alpha_q_original(k)];astar=[S.alpha_d_oracle(k);S.alpha_q_oracle(k)];
iM=[L.measured_id_A(k);L.measured_iq_A(k)];i=[S.id(k);S.iq(k)];
F={ [S.Fd_original(k);S.Fq_original(k)], [S.Fd_original(k);S.Fq_original(k)], ...
    [S.Fd_oracle_previous(k);S.Fq_oracle_previous(k)], [S.Fd_oracle_instant(k);S.Fq_oracle_instant(k)], ...
    [S.Fd_oracle_acausal(k);S.Fq_oracle_acausal(k)], ...
    [S.Fd_oracle_previous_alpha_oracle(k);S.Fq_oracle_previous_alpha_oracle(k)], ...
    [S.Fd_oracle_instant(k);S.Fq_oracle_instant(k)], ...
    [S.Fd_oracle_acausal_alpha_oracle(k);S.Fq_oracle_acausal_alpha_oracle(k)]};
A={a0,astar,a0,a0,a0,astar,astar,astar};I={iM,iM,i,i,i,i,i,i};
for p=1:8
    timer=tic;
    if all(isfinite(F{p}))
        i1=I{p}+Ts*(F{p}+A{p}.*uP);
        for c=1:C
            if bank(c).valid
                uS=eq_voltage(bank(c).command,simulation.vectors,theta,omega,1,Ts);
                pred(c,:,p)=(i1+Ts*(F{p}+A{p}.*uS)).';
            end
        end
    end
    timing(p)=toc(timer);
end
timer=tic;f0=physical_F(i,omega,m);i1=i+Ts*(f0+astar.*uP);f1=physical_F(i1,omega,m);
for c=1:C
    if bank(c).valid
        uS=eq_voltage(bank(c).command,simulation.vectors,theta,omega,1,Ts);
        pred(c,:,9)=(i1+Ts*(f1+astar.*uS)).';
    end
end
timing(9)=toc(timer);
timer=tic;pred(:,:,10)=evaluate_p5(project,simulation,L,k,pending,bank,project.model_error.candidate_integration_step_s);timing(10)=toc(timer);
end

function prediction=evaluate_p5(project,simulation,L,k,pending,bank,step)
Ts=project.paper.Ts_s;omega=L.omega_e_rad_s(k);state=[L.id_A(k);L.iq_A(k);L.theta_e_rad(k)];
[state,~,~]=zhou_ipmsm.model.integrate_command(state,pending,simulation.vectors,omega,simulation.plant_motor,Ts,project.assumptions.time_tolerance_s,[0 0],step);
prediction=nan(numel(bank),2);
for c=1:numel(bank)
    if bank(c).valid
        [x,~,~]=zhou_ipmsm.model.integrate_command(state,bank(c).command,simulation.vectors,omega,simulation.plant_motor,Ts,project.assumptions.time_tolerance_s,[0 0],step);
        prediction(c,:)=x(1:2).';
    end
end
end

function [bank,finalIndex]=diagnostic_bank(L,k,vectors,Ts,a)
raw=repmat(candidate_template(),0,1);
raw(end+1)=make_candidate("final_selected","closed_loop_final",trace_command(L,k,"selected",vectors,Ts),vectors,Ts); %#ok<AGROW>
raw(end+1)=make_candidate("pre_S2_core","pre_S2_core",trace_command(L,k,"original",vectors,Ts),vectors,Ts); %#ok<AGROW>
raw(end+1)=make_candidate("V0_zero","coverage_probe",zhou_ipmsm.modulation.case1_command(Ts,vectors),vectors,Ts); %#ok<AGROW>
for id=1:6
    c=zhou_ipmsm.modulation.case2_command(vectors.ab_V(id+1,:),id,Ts,vectors,a.duty_tolerance);
    raw(end+1)=make_candidate("V"+id+"_full","coverage_probe",c,vectors,Ts); %#ok<AGROW>
end
lo=[1,3,3,5,5,1];hi=[2,2,4,4,6,6];
for sector=1:6
    center=(vectors.ab_V(lo(sector)+1,:)+vectors.ab_V(hi(sector)+1,:))/3;
    c=zhou_ipmsm.modulation.case3_command(center,Ts,vectors,a.sector_angle_tolerance_rad,a.duty_tolerance);
    raw(end+1)=make_candidate("sector_"+sector+"_three_vector_center","coverage_probe",c,vectors,Ts); %#ok<AGROW>
end
bank=repmat(candidate_template(),0,1);
for j=1:numel(raw)
    hit=find(string({bank.signature})==raw(j).signature,1);
    if isempty(hit),bank(end+1)=raw(j);else,bank(hit).aliases=bank(hit).aliases+"|"+raw(j).name;end %#ok<AGROW>
end
finalIndex=find(contains(string({bank.aliases}),"final_selected"),1);assert(~isempty(finalIndex)&&bank(finalIndex).valid);
end

function c=make_candidate(name,origin,command,vectors,Ts)
c=candidate_template();c.name=string(name);c.aliases=c.name;c.origin=string(origin);c.command=command;
c.signature=signature(command,Ts);c.valid=integrable(command,Ts);c.mode=physical_mode(command,Ts);
c.equivalent_ab=zeros(1,2);for j=1:numel(command.sequence_vector_ids),c.equivalent_ab=c.equivalent_ab+command.sequence_durations_s(j)/Ts*vectors.ab_V(command.sequence_vector_ids(j)+1,:);end
end

function c=candidate_template()
c=struct('name',"",'aliases',"",'origin',"",'signature',"",'mode',"",'valid',false,'equivalent_ab',[NaN NaN],'command',struct());
end

function command=trace_command(L,k,kind,vectors,Ts)
switch kind
    case "selected",ids=L.selected_sequence_vector_ids(k);dur=L.selected_sequence_durations_s(k);
    case "applied",ids=L.applied_sequence_vector_ids(k);dur=L.applied_sequence_durations_s(k);
    case "original",ids=L.original_sequence_vector_ids(k);dur=L.original_sequence_durations_s(k);
end
command=struct('sequence_vector_ids',parse_list(ids),'sequence_durations_s',parse_list(dur));
command.sequence_vector_ids=command.sequence_vector_ids(:).';command.sequence_durations_s=command.sequence_durations_s(:).';
command.equivalent_ab_V=zeros(1,2);for j=1:numel(command.sequence_vector_ids),command.equivalent_ab_V=command.equivalent_ab_V+command.sequence_durations_s(j)/Ts*vectors.ab_V(command.sequence_vector_ids(j)+1,:);end
end

function values=parse_list(text)
tokens=regexp(regexprep(char(string(text)),'[\[\]\(\)]',''),'[;,\s]+','split');tokens=tokens(~cellfun('isempty',tokens));values=str2double(tokens);assert(all(isfinite(values)));
end

function yes=integrable(c,Ts)
yes=numel(c.sequence_vector_ids)==numel(c.sequence_durations_s)&&~isempty(c.sequence_vector_ids)&& ...
    all(c.sequence_vector_ids>=0&c.sequence_vector_ids<=6&c.sequence_vector_ids==round(c.sequence_vector_ids))&& ...
    all(c.sequence_durations_s>=-1e-13)&&abs(sum(c.sequence_durations_s)-Ts)<=max(1e-13,100*eps(Ts));
end

function value=signature(c,Ts)
ids=c.sequence_vector_ids(:).';d=round(c.sequence_durations_s(:).'/Ts,12);keep=abs(d)>1e-12;ids=ids(keep);d=d(keep);
if isempty(ids),value="empty";return,end
mi=ids(1);md=d(1);for j=2:numel(ids),if ids(j)==mi(end),md(end)=md(end)+d(j);else,mi(end+1)=ids(j);md(end+1)=d(j);end,end %#ok<AGROW>
parts=strings(size(mi));for j=1:numel(mi),parts(j)=sprintf('V%d@%.12g',mi(j),md(j));end;value=strjoin(parts,'>');
end

function mode=physical_mode(c,Ts)
keep=c.sequence_durations_s>max(100*eps(Ts),1e-15);n=numel(unique(c.sequence_vector_ids(keep),'stable'));
if n==1,mode="one_vector";elseif n==2,mode="two_vector";elseif n==3,mode="three_vector";else,mode="multi_vector_"+n;end
end

function order=stable_order(score,valid)
ix=find(valid&isfinite(score));if isempty(ix),order=[];return,end
[~,p]=sort(score(ix),'ascend');order=ix(p);start=1;
while start<=numel(order)
    base=score(order(start));last=start;tol=1e-9*(1+abs(base));
    while last<numel(order)&&abs(score(order(last+1))-base)<=tol,last=last+1;end
    order(start:last)=sort(order(start:last));start=last+1;
end
end

function u=eq_voltage(c,v,theta,omega,delay,Ts)
u=zhou_ipmsm.controller.sequence_equivalent_dq_voltage(c,v,theta,omega,delay,Ts,"execution_segment_midpoint");
end

function F=physical_F(i,w,m)
F=[-m.Rs_Ohm/m.Ld_H*i(1)+w*m.Lq_H/m.Ld_H*i(2);-m.Rs_Ohm/m.Lq_H*i(2)-w*m.Ld_H/m.Lq_H*i(1)-w*m.psi_f_Wb/m.Lq_H];
end

function value=signature_set(s),value=strjoin(sort(unique(s(:))),'||');end
function value=jaccard(a,b),a=unique(a);b=unique(b);value=numel(intersect(a,b))/numel(union(a,b));end

function value=causality(name)
if ismember(name,["P0","P1"]),value="causal_original";elseif ismember(name,["P2a","P3a"]),value="causal_previous_period_oracle";elseif ismember(name,["P2b","P3b","P4"]),value="offline_physical_parameter_oracle";elseif ismember(name,["P2c","P3c"]),value="noncausal_future_endpoint_oracle";else,value="offline_plant_replay_oracle";end
end

function r=detail_template()
r=struct('case_id',"",'case_category',"",'range_class',"",'sample_index',NaN,'time_s',NaN, ...
    'predictor',"",'causality_class',"",'predictor_valid',false,'ranking_valid',false,'ranking_invalid_reason',"", ...
    'candidate_count',NaN,'candidate_bank_semantics',"",'S2_triggered',false,'actual_joint_pass',false, ...
    'top1_name',"",'top1_signature',"",'top1_mode',"",'top1_score',NaN,'top1_joint_feasible',false, ...
    'top2_name',"",'top2_signature',"",'top3_name',"",'top3_signature',"",'top3_set_signature',"", ...
    'top1_voltage_alpha_V',NaN,'top1_voltage_beta_V',NaN,'final_selected_signature',"",'final_selected_mode',"", ...
    'final_selected_rank',NaN,'final_selected_joint_feasible',false,'final_selected_false_safe',false, ...
    'final_selected_false_alarm',false,'diagnostic_top1_voltage_changed',false,'top1_flip_vs_P0',false, ...
    'top3_set_flip_vs_P0',false,'mode_flip_vs_P0',false,'feasibility_flip_vs_P0',false, ...
    'top1_agrees_with_P5',NaN,'mode_agrees_with_P5',NaN,'top1_recovery_eligible',NaN,'top1_recovered',NaN, ...
    'top1_new_error',NaN,'mode_recovery_eligible',NaN,'mode_recovered',NaN,'mode_new_error',NaN, ...
    'top3_jaccard_vs_P5',NaN,'evaluation_time_s',NaN);
end
