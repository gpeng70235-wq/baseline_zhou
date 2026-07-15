function g = excitation_gate(axis,u_hp,residual_jump,state,p)
%EXCITATION_GATE Per-axis closed-form conditioning and excitation checks.
window=state.u_hp_window(axis,1:min(state.window_count,p.excitation_window));
g=struct('pass',false,'reason',"window_incomplete",'energy',sum(window.^2), ...
    'rcond',0,'amplitude',abs(u_hp),'slow_tick',false);
g.slow_tick=mod(double(state.sample_index),p.N_alpha)==0;
if state.window_count<p.excitation_window, return; end
scale=max(p.u_hp_min(axis),sqrt(mean(window.^2)));
Phi=[ones(numel(window),1),window(:)/max(scale,eps)];
g.rcond=rcond(Phi.'*Phi);
if abs(u_hp)<=p.u_hp_min(axis),g.reason="u_hp_below_threshold";return;end
if g.energy<=p.E_u_min(axis),g.reason="window_energy_low";return;end
if g.rcond<p.regressor_rcond_min(axis),g.reason="regressor_ill_conditioned";return;end
if state.zero_vector_run>p.max_zero_vector_run,g.reason="zero_vector_run";return;end
if abs(residual_jump)>p.residual_jump_max(axis),g.reason="residual_jump";return;end
g.pass=true;g.reason="excitation_good";
end
