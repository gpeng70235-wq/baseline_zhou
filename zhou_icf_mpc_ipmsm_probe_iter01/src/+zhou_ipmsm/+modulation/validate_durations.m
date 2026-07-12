function ok=validate_durations(d,Ts,tol),if nargin<3,tol=1e-12;end,ok=all(d>=-tol)&&abs(sum(d)-Ts)<=tol;end
