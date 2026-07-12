function F=estimate_ultralocal_F(i,iprev,u,alpha,Ts,valid),if valid,F=(i-iprev)/Ts-alpha(:).*u;else,F=[0;0];end,end
