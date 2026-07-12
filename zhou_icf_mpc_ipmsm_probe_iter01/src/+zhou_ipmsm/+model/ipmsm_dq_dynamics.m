function dx=ipmsm_dq_dynamics(x,u,omega_e,p)
dx=[(u(1)-p.Rs*x(1)+omega_e*p.Lq*x(2))/p.Ld;(u(2)-p.Rs*x(2)-omega_e*(p.Ld*x(1)+p.psi_f))/p.Lq];
end
