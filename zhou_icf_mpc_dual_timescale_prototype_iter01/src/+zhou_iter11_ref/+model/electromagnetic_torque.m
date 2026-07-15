function torque_Nm = electromagnetic_torque(iq_A, motor)
%ELECTROMAGNETIC_TORQUE SMPMSM torque used only for requested metrics (A11).

torque_Nm = 1.5 * motor.pole_pairs * motor.psi_f_Wb .* iq_A;
end

