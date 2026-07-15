function Fhat=estimate_F_algebraic(current_history,voltage_history,alpha_dq,Ts)
%ESTIMATE_F_ALGEBRAIC Fliess-Join 2013 Sec. 3.4.1 weighted integral.
% Current is linearly interpolated; applied voltage is ZOH on each interval.

arguments
    current_history (2,:) double {mustBeFinite}
    voltage_history (2,:) double {mustBeFinite}
    alpha_dq (2,1) double {mustBePositive,mustBeFinite}
    Ts (1,1) double {mustBePositive,mustBeFinite}
end
N=size(voltage_history,2);
assert(size(current_history,2)==N+1 && N>=1,'ZhouIter11Ref:EstimatorHistory', ...
    'Algebraic estimator needs N+1 currents and N applied voltages.');
L=N*Ts;
integral_value=zeros(2,1);
for j=1:N
    left=(j-1)*Ts;right=j*Ts;
    slope=(current_history(:,j+1)-current_history(:,j))/Ts;
    intercept=current_history(:,j)-slope*left;
    int_y=intercept.*(L*(right-left)-(right^2-left^2)) + ...
        slope.*(L/2*(right^2-left^2)-2/3*(right^3-left^3));
    int_u=L/2*(right^2-left^2)-1/3*(right^3-left^3);
    integral_value=integral_value+int_y+alpha_dq.*voltage_history(:,j)*int_u;
end
Fhat=-6/L^3*integral_value;
end

