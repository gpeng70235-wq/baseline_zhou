function c=calculate_torque_components(i,p),c.magnet=1.5*p.pole_pairs*p.psi_f*i(2);c.reluctance=1.5*p.pole_pairs*(p.Ld-p.Lq)*i(1)*i(2);c.total=c.magnet+c.reluctance;end
