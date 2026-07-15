function [Fpost,Fpred] = F_update(Fprior,Fprevious,y,u,alpha,gate,decision_latched,p)
%F_UPDATE Same-gauge posterior F update and optional one-row-latched trend.
Fpost=Fprior(:);
if p.freeze_F,Fpred=Fpost;return;end
for x=1:2
    if gate(x)
        Fmeas=y(x)-alpha(x)*u(x);
        Fpost(x)=Fprior(x)+p.beta_F(x)*(Fmeas-Fprior(x));
    end
end
Fpost=min(p.F_max,max(-p.F_max,Fpost));
Fpred=Fpost;
if decision_latched
    % Fprior is exactly F_post(k-1); do not reach back to k-2.
    Fpred=Fpost+p.rho_F.*(Fpost-Fprior(:));
    Fpred=min(p.F_max,max(-p.F_max,Fpred));
end
end
