function components = torque_components(current, motor)
%TORQUE_COMPONENTS Permanent-magnet and reluctance torque decomposition.

if size(current,1)==2
    id_A=current(1,:).'; iq_A=current(2,:).';
elseif size(current,2)==2
    id_A=current(:,1); iq_A=current(:,2);
else
    error('ZhouIPMSM:TorqueShape','Current must contain d and q axes.');
end
scale=1.5*motor.pole_pairs;
components.magnet_Nm=scale*motor.psi_f_Wb.*iq_A;
components.reluctance_Nm=scale*(motor.Ld_H-motor.Lq_H).*id_A.*iq_A;
components.total_Nm=components.magnet_Nm+components.reluctance_Nm;
end
