function value = calculate_torque_ripple(torque)
%CALCULATE_TORQUE_RIPPLE Frozen standard-deviation definition.
value=std(torque,0,'omitnan');
end
