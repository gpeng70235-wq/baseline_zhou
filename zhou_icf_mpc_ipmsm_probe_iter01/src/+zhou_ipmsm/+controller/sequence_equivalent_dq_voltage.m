function u=sequence_equivalent_dq_voltage(c,v,theta,omega,delay,Ts,mode)
if strcmp(mode,'legacy_selection_angle'),u=zhou_ipmsm.inverter.park(c.reference_ab_V,theta);return,end;d=c.sequence_durations_s(:);ids=c.sequence_vector_ids(:);st=[0;cumsum(d(1:end-1))];u=[0;0];for k=1:numel(d),u=u+d(k)/Ts*zhou_ipmsm.inverter.park(v.ab_V(ids(k)+1,:),theta+omega*(delay*Ts+st(k)+d(k)/2));end
end
