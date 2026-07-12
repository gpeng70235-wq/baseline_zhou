function v=voltage_vectors(Vdc),v.ids=(0:6)';v.states=[0 0 0;1 0 0;1 1 0;0 1 0;0 1 1;0 0 1;1 0 1];a=(0:5)'*pi/3;v.ab_V=[0 0;(2/3*Vdc)*[cos(a) sin(a)]];end
