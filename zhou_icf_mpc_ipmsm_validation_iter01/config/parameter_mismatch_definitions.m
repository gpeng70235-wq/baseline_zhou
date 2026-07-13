function d = parameter_mismatch_definitions()
%PARAMETER_MISMATCH_DEFINITIONS Plant-only mismatch grids.

d.sensitivity_parameters = ["Ld" "Lq" "Rs" "psi_f"];
d.sensitivity_scales = [0.8 0.9 1.0 1.1 1.2];
d.stress.Ld = [0.5 1.5];
d.stress.Lq = [0.5 1.5];
d.stress.Rs = [0.5 1.5];
d.stress.psi_f = [0.8 1.2];
d.stress.combined = struct('Ld',0.8,'Lq',1.2,'Rs',1.2,'psi_f',0.9);
d.controller_policy = "nominal_fixed_no_synchronous_update";
d.scope_label = "parameter sensitivity / stress test; not temperature or saturation";
end
