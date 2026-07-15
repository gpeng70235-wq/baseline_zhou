function derivative = pmsm_derivative(state, voltage_ab, omega_e, motor, delta_voltage_ab)
%PMSM_DERIVATIVE Paper equation (1), including Delta_ud/q disturbance.
% state = [id;iq;theta_e].

if nargin<5
    delta_voltage_ab=[0,0];
end

id = state(1);
iq = state(2);
theta = state(3);
voltage_dq = zhou_iter11_ref.math.park(voltage_ab, theta);
delta_dq = zhou_iter11_ref.math.park(delta_voltage_ab,theta);
delta_ud = delta_dq(1);
delta_uq = delta_dq(2);

did = voltage_dq(1)/motor.Ls_H - motor.Rs_Ohm/motor.Ls_H*id + ...
    omega_e*iq - delta_ud/motor.Ls_H;
diq = voltage_dq(2)/motor.Ls_H - motor.Rs_Ohm/motor.Ls_H*iq - ...
    omega_e*(motor.Ls_H*id + motor.psi_f_Wb)/motor.Ls_H - ...
    delta_uq/motor.Ls_H;

derivative = [did; diq; omega_e];
end
