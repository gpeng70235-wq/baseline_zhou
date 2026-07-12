function motor = ipmsm_parameters()
%IPMSM_PARAMETERS Motor data and declared IPMSM saliency assumptions.
motor.type = 'IPMSM';
motor.Ld = 0.8e-3;
motor.Lq = 1.2e-3;
motor.Rs = 0.0957;
motor.psi_f = 0.027;
motor.pole_pairs = 12;
motor.inertia = 0.01015;
end
