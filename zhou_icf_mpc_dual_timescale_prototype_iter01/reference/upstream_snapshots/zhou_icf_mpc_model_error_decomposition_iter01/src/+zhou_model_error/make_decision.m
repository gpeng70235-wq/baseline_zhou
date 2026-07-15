function decision=make_decision(project,T,S)
%MAKE_DECISION Apply the preregistered A--F attribution gates.
O=S.contribution(S.contribution.cohort=="ENGINEERING_PRIMARY",:);assert(height(O)==1);
M=S.predictor_metrics(S.predictor_metrics.cohort=="ENGINEERING_PRIMARY",:);
rate=@(p)M.false_safe_joint_rate(M.predictor==p);
caseIds=unique(T.case_id(T.range_class~="stress_test"),'stable');K=S.contribution(S.contribution.cohort_type=="case"&ismember(S.contribution.cohort,caseIds),:);
fCase=mean(K.Delta_F_instant_A2>=.2*K.MSE_P0_A2);aCase=mean(K.Delta_alpha_A2>=.2*K.MSE_P0_A2);
sCase=mean(K.Delta_structure_total_A2>=.2*K.MSE_P0_A2);
fShare=O.F_share_of_explained;aShare=O.alpha_share_of_explained;sShare=O.structure_share_of_explained;
fFalseSafeDrop=rate("P0")-rate("P2b");aFalseSafeDrop=rate("P0")-rate("P1");jointDrop=rate("P0")-rate("P3b");
jointSynergy=O.Delta_joint_instant_A2-max(O.Delta_F_instant_A2,O.Delta_alpha_A2);
parameterIds=unique(T.case_id(T.case_category=="parameter"&T.range_class~="stress_test"),'stable');
KP=K(ismember(K.cohort,parameterIds),:);
parameterInteractionPositive=mean(KP.Delta_F_alpha_interaction_excess_A2>0);
parameterJointBeatsBoth=mean(KP.MSE_P3b_A2<min(KP.MSE_P1_A2,KP.MSE_P2b_A2));
candidate=S.candidate(S.candidate.cohort=="ENGINEERING_PRIMARY",:);
fRecovery=value(candidate,"P2b","top1_recovery_rate");aRecovery=value(candidate,"P1","top1_recovery_rate");
structureRecovery=value(candidate,"P4","top1_recovery_rate");
spec=S.spectrum(S.spectrum.predictor=="P0"&S.spectrum.spectrum_valid,:);
periodicDominantFraction=mean(ismember(round(spec.dominant_order_1,10),[6,12]));

gateE=false;
gateA=fShare>=.60&&fCase>=.60&&O.Delta_F_instant_A2>=.20*O.MSE_P0_A2&&fFalseSafeDrop>=.005;
gateB=aShare>=.60&&aCase>=.60&&O.Delta_alpha_A2>=.20*O.MSE_P0_A2&&aFalseSafeDrop>=.005;
gateC=fShare>=.20&&aShare>=.20&&jointSynergy>=.10*O.MSE_P0_A2&&jointDrop>=.005&& ...
    parameterInteractionPositive>=.75&&parameterJointBeatsBoth>=.75;
gateD=(O.MSE_P3b_A2/O.MSE_P0_A2)>=.25&&sShare>=.25&&sCase>=.60&&O.Delta_structure_total_A2>=.20*O.MSE_P0_A2;
stressFraction=mean(T.false_safe_P0(T.range_class=="stress_test"))*nnz(T.range_class=="stress_test")/max(1,nnz(T.false_safe_P0));
gateF=~(gateA||gateB||gateC||gateD)&&stressFraction>.80;
if gateE,code="E";label="implementation, timing, or metric defect";route="repair implementation before proposing an algorithm";
elseif gateA,code="A";label="F estimation error is the primary source";route="separate project on F-estimator bandwidth, predictive F estimation, or ESO";
elseif gateB,code="B";label="alpha input-gain error is the primary source";route="separate project on online/scheduled alpha_d and alpha_q estimation";
elseif gateC,code="C";label="F and alpha jointly dominate";route="separate compute-bounded extended-affine ultralocal study";
elseif gateD,code="D";label="two-period freezing/discretization or first-order structure dominates";route="separate higher-order, extended-affine, or more exact discretization study";
else,code="F";label="no stable engineering-value attribution route under the registered gates";route="stop the ultralocal robustness-improvement route";end
if code=="F"&&~gateF
    label="no A-D gate is met with stable multi-case evidence";
end
if periodicDominantFraction>=.60
    route=route+"; independently audit the stable 6x/12x electrical-periodic residual before considering any resonator";
end
decision=table(code,label,route,gateA,gateB,gateC,gateD,gateE,gateF, ...
    O.registered_sample_count,O.common_sample_count,rate("P0"),rate("P1"),rate("P2a"),rate("P2b"), ...
    rate("P3a"),rate("P3b"),rate("P4"),rate("P5"),fShare,aShare,sShare,fCase,aCase,sCase, ...
    fFalseSafeDrop,aFalseSafeDrop,jointDrop,fRecovery,aRecovery,structureRecovery, ...
    parameterInteractionPositive,parameterJointBeatsBoth,height(spec),periodicDominantFraction,stressFraction, ...
    'VariableNames',{'decision_code','decision_label','recommended_route','gate_A','gate_B','gate_C','gate_D','gate_E','gate_F', ...
    'registered_sample_count','common_sample_count','P0_false_safe_rate','P1_false_safe_rate','P2a_false_safe_rate','P2b_false_safe_rate', ...
    'P3a_false_safe_rate','P3b_false_safe_rate','P4_false_safe_rate','P5_false_safe_rate', ...
    'F_share','alpha_share','structure_share','material_F_case_fraction','material_alpha_case_fraction', ...
    'material_structure_case_fraction','F_false_safe_drop','alpha_false_safe_drop','joint_false_safe_drop', ...
    'F_top1_recovery_rate','alpha_top1_recovery_rate','structure_top1_recovery_rate', ...
    'parameter_case_positive_interaction_fraction','parameter_case_joint_beats_both_single_fraction', ...
    'P0_valid_spectrum_axis_count','P0_6x_12x_dominant_axis_fraction','stress_false_safe_event_fraction'});
writetable(decision,fullfile(project.dirs.summary,'final_decision.csv'));
end

function v=value(T,p,field)
q=T.predictor==p;if any(q),v=T.(field)(find(q,1));else,v=NaN;end
end
