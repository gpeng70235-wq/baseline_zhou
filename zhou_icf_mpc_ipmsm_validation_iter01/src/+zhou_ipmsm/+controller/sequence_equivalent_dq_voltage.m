function [u_dq,angles]=sequence_equivalent_dq_voltage(command,vectors,theta_sample,omega_e,delay_periods,Ts,mode)
% Uses only sampled angle/speed and candidate sequence metadata.
if mode=="legacy_selection_angle"
    angles=repmat(theta_sample,size(command.sequence_durations_s));
    u_dq=zhou_ipmsm.math.park(command.reference_ab_V,theta_sample);return
end
d=command.sequence_durations_s(:);ids=command.sequence_vector_ids(:);starts=[0;cumsum(d(1:end-1))];
angles=mod(theta_sample+omega_e*(delay_periods*Ts+starts+d/2),2*pi);
u_dq=[0;0];for j=1:numel(d),u_dq=u_dq+d(j)/Ts*zhou_ipmsm.math.park(vectors.ab_V(ids(j)+1,:),angles(j));end
end
