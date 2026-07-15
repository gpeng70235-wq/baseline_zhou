function reference_dq=build_current_reference(id_ref_A,iq_ref_A,ramp)
%BUILD_CURRENT_REFERENCE Shared d/q ramp used by negative-id admission runs.
if nargin<3,ramp=1;end
reference_dq=ramp*[id_ref_A;iq_ref_A];
end
