function [k1,k2] = dual_timescale_predictor(i,Fpred,alpha,u_pending,u_selected,Ts)
%DUAL_TIMESCALE_PREDICTOR Two distinct Ts Euler steps with causal commands.
k1=i(:)+Ts*(Fpred(:)+alpha(:).*u_pending(:));
k2=k1+Ts*(Fpred(:)+alpha(:).*u_selected(:));
assert(all(isfinite([k1;k2])),'Prototype:NonfinitePrediction');
end
