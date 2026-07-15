function [delta_ab_V,audit]=deadtime_voltage_error(command,current_dq,theta_e, ...
        dc_bus_V,dead_time_s,Ts,current_zero_tolerance_A)
%DEADTIME_VOLTAGE_ERROR Averaged Table-III dead-time disturbance for Eq. (1).
% delta_ab is commanded minus effective voltage and is invisible to control.

arguments
    command struct
    current_dq (2,1) double {mustBeFinite}
    theta_e (1,1) double {mustBeFinite}
    dc_bus_V (1,1) double {mustBePositive}
    dead_time_s (1,1) double {mustBeNonnegative}
    Ts (1,1) double {mustBePositive}
    current_zero_tolerance_A (1,1) double {mustBeNonnegative} = 1e-9
end

from_states=zeros(0,3);to_states=zeros(0,3);
if size(command.sequence_states,1)>1
    from_states=command.sequence_states(1:end-1,:);
    to_states=command.sequence_states(2:end,:);
elseif isfield(command,'deadtime_transition_from_state')
    from_states=command.deadtime_transition_from_state;
    to_states=command.deadtime_transition_to_state;
end

transitions=to_states-from_states;
rising_count=sum(transitions==1,1);
falling_count=sum(transitions==-1,1);
current_abc=zhou_iter11_ref.model.phase_currents(current_dq,theta_e).';
current_sign=sign(current_abc);
current_sign(abs(current_abc)<=current_zero_tolerance_A)=0;

% With positive current, only a 0->1 blanking interval changes voltage;
% with negative current, only a 1->0 interval does. Each adverse event loses
% one Vdc*td volt-second relative to the ideal command.
adverse_count=(current_sign>0).*rising_count+(current_sign<0).*falling_count;
delta_phase_V=dc_bus_V*(dead_time_s/Ts).*current_sign.*adverse_count;
delta_alpha_V=(2/3)*(delta_phase_V(1)-0.5*delta_phase_V(2)-0.5*delta_phase_V(3));
delta_beta_V=(2/3)*(sqrt(3)/2)*(delta_phase_V(2)-delta_phase_V(3));
delta_ab_V=[delta_alpha_V,delta_beta_V];

audit=struct();
audit.current_abc_A=current_abc;
audit.current_sign=current_sign;
audit.rising_count=rising_count;
audit.falling_count=falling_count;
audit.adverse_count=adverse_count;
audit.delta_phase_V=delta_phase_V;
audit.delta_ab_V=delta_ab_V;
audit.model="average_deadtime_volt_second_error_A21";
end
