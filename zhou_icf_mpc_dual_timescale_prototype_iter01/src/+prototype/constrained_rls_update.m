function [state,diag] = constrained_rls_update(state,y,u,excitation,s2_ok,p)
%CONSTRAINED_RLS_UPDATE Projected two-parameter RLS upper-bound comparator.
diag=struct('updated',false(2,1),'projection_hit',false(2,1));
if ~s2_ok, return; end
for x=1:2
    P=state.rls_P(:,:,x); phi=[1;u(x)];
    K=P*phi/(p.rls_lambda+phi.'*P*phi);
    if ~excitation(x), K(2)=0; end
    theta=[state.F(x);state.alpha(x)];
    raw=theta+K*(y(x)-phi.'*theta);
    raw(1)=(1-p.rls_mu_F)*raw(1);
    state.F(x)=min(p.F_max(x),max(-p.F_max(x),raw(1)));
    state.alpha(x)=min(p.alpha_max(x),max(p.alpha_min(x),raw(2)));
    diag.projection_hit(x)=state.alpha(x)~=raw(2);
    P=(eye(2)-K*phi.')*P/p.rls_lambda;
    P=(P+P.')/2;
    [V,D]=eig(P); ev=min(p.rls_P_max,max(p.rls_P_min,builtin('diag',D)));
    state.rls_P(:,:,x)=V*builtin('diag',ev)*V.';
    diag.updated(x)=true;
end
end
