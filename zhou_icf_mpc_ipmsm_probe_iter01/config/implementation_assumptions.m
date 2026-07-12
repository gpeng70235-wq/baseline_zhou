function assumptions = implementation_assumptions()
%IMPLEMENTATION_ASSUMPTIONS Explicit policies for paper ambiguities.
assumptions.frame_mode = 'execution_segment_midpoint';
assumptions.integrator = 'rk4_per_sequence_segment_with_rotating_frame';
assumptions.speed = 'constant';
assumptions.inverter = 'ideal_two_level';
assumptions.estimator = 'causal_euler';
assumptions.case2_midpoint = 'geometric_paper_prose_with_Table_I_selection';
end
