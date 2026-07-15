function [alpha,hit] = alpha_update(alpha_prior,u_hp,y_hp,mask,step_scale,p)
%ALPHA_UPDATE Slow normalized projected update, independently per axis.
alpha=alpha_prior(:); hit=false(2,1);
for x=1:2
    if mask(x)
        e=y_hp(x)-alpha_prior(x)*u_hp(x);
        raw=alpha_prior(x)+step_scale*p.gamma_alpha(x)*u_hp(x)*e/ ...
            (p.epsilon_alpha(x)+u_hp(x)^2);
        alpha(x)=min(p.alpha_max(x),max(p.alpha_min(x),raw));
        hit(x)=alpha(x)~=raw;
    end
end
end
