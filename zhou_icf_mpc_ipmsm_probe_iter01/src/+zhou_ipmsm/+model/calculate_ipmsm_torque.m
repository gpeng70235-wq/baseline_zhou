function T = calculate_ipmsm_torque(i, p)
%CALCULATE_IPMSM_TORQUE Electromagnetic torque including saliency torque.
components = zhou_ipmsm.model.calculate_torque_components(i, p);
T = components.total;
end
