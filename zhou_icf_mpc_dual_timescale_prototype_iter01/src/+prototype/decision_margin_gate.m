function [gate,mJ] = decision_margin_gate(Jd,Jq,Jd_limit,Jq_limit,native_mode_gap,valid,p)
%DECISION_MARGIN_GATE Current native decision; caller latches for next row.
mJ=min(Jd_limit-Jd,Jq_limit-Jq);
near_safe=isfinite(mJ)&&mJ>=0&&mJ<=p.delta_J_A2;
near_mode=isfinite(native_mode_gap)&&abs(native_mode_gap)<=p.delta_mode_gap_A2;
gate=logical(valid&&(near_safe||near_mode));
end
