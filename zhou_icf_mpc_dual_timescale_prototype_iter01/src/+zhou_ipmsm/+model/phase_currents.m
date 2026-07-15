function currents_abc = phase_currents(current_dq, theta_e)
%PHASE_CURRENTS dq to abc using equation (6) plus amplitude-invariant Clarke.

current_ab = zhou_ipmsm.math.inv_park(current_dq, theta_e);
ia = current_ab(1);
ib = -0.5*current_ab(1) + sqrt(3)/2*current_ab(2);
ic = -0.5*current_ab(1) - sqrt(3)/2*current_ab(2);
currents_abc = [ia; ib; ic];
end

