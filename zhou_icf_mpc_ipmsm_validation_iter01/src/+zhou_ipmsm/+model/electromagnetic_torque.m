function torque_Nm = electromagnetic_torque(current, motor)
%ELECTROMAGNETIC_TORQUE Total IPMSM torque for dq samples.
% CURRENT may be [id;iq], an N-by-2 matrix, or iq alone for compatibility.

if isvector(current) && numel(current)==2
    id_A = current(1);
    iq_A = current(2);
elseif ismatrix(current) && size(current,2)==2
    id_A = current(:,1);
    iq_A = current(:,2);
else
    id_A = zeros(size(current));
    iq_A = current;
end
if isfield(motor,'Ld_H'), Ld=motor.Ld_H; else, Ld=motor.Ls_H; end
if isfield(motor,'Lq_H'), Lq=motor.Lq_H; else, Lq=motor.Ls_H; end
torque_Nm = 1.5*motor.pole_pairs.*(motor.psi_f_Wb.*iq_A + ...
    (Ld-Lq).*id_A.*iq_A);
end
