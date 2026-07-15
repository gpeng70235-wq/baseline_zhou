function derivative = pmsm_derivative(state, voltage_ab, omega_e, motor, delta_voltage_ab)
%PMSM_DERIVATIVE IPMSM dq model, including Delta_ud/q disturbance.
% state = [id;iq;theta_e].

if nargin<5
    delta_voltage_ab=[0,0];
end

id = state(1);
iq = state(2);
theta = state(3);
voltage_dq = zhou_ipmsm.math.park(voltage_ab, theta);
delta_dq = zhou_ipmsm.math.park(delta_voltage_ab,theta);
delta_ud = delta_dq(1);
delta_uq = delta_dq(2);

if isfield(motor,'Ld_H'), Ld = motor.Ld_H; else, Ld = motor.Ls_H; end
if isfield(motor,'Lq_H'), Lq = motor.Lq_H; else, Lq = motor.Ls_H; end

% Preserve the exact Iteration 11 floating-point expression in the P0
% degenerate limit. This makes the inheritance gate sensitive to controller
% differences instead of harmless algebraic reassociation.
if Ld == Lq && Ld == motor.Ls_H
    did = voltage_dq(1)/motor.Ls_H - motor.Rs_Ohm/motor.Ls_H*id + ...
        omega_e*iq - delta_ud/motor.Ls_H;
    diq = voltage_dq(2)/motor.Ls_H - motor.Rs_Ohm/motor.Ls_H*iq - ...
        omega_e*(motor.Ls_H*id + motor.psi_f_Wb)/motor.Ls_H - ...
        delta_uq/motor.Ls_H;
else
    did = (voltage_dq(1)-motor.Rs_Ohm*id+omega_e*Lq*iq-delta_ud)/Ld;
    diq = (voltage_dq(2)-motor.Rs_Ohm*iq- ...
        omega_e*(Ld*id+motor.psi_f_Wb)-delta_uq)/Lq;
end

derivative = [did; diq; omega_e];
end
