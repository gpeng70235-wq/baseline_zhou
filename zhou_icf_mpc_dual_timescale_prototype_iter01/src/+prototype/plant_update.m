function [next_state,u_app,audit] = plant_update(state,command,vectors,omega,motor,Ts,tol,delta,substep)
%PLANT_UPDATE Named wrapper around the byte-identical frozen RK4 plant.
[next_state,u_app,audit]=zhou_ipmsm.model.integrate_command(state,command, ...
    vectors,omega,motor,Ts,tol,delta,substep);
end
