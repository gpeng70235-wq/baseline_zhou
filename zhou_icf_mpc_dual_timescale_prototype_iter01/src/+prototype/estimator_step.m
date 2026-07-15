function [state,d] = estimator_step(state,method,current,previous,u_app,quality,original_F,p)
%ESTIMATOR_STEP Causal B1/B2/P/RLS estimator update at row k.
method=string(method); state.sample_index=state.sample_index+1;
d=struct('y',[NaN;NaN],'u_hp',[NaN;NaN],'y_hp',[NaN;NaN], ...
    'gate_exc',false(2,1),'gate_s2',quality.pass,'alpha_update',false(2,1), ...
    'freeze_reason',[quality.reason;quality.reason],'projection_hit',false(2,1), ...
    'energy',[NaN;NaN],'rcond',[NaN;NaN],'residual_jump',[NaN;NaN], ...
    'state',["startup";"startup"]);
if quality.zero_command,state.zero_vector_run=state.zero_vector_run+1;else,state.zero_vector_run=0;end
if ~all(isfinite([current(:);previous(:);u_app(:)]))
    state=prototype.estimator_initialize(p);state.reset_count=state.reset_count+1;
    d.freeze_reason(:)="hard_reset_nonfinite";d.state(:)="hard_reset";return
end
if ~state.history_valid
    if quality.pass
        state.u_bar=u_app(:);state.y_bar=(current(:)-previous(:))/p.Ts_s;
        state.history_valid=true;state.status(:)="warmup";
    end
    d.state=state.status;return
end
d.y=(current(:)-previous(:))/p.Ts_s;
state.u_bar=state.u_bar+p.beta_u.*(u_app(:)-state.u_bar);
state.y_bar=state.y_bar+p.beta_y.*(d.y-state.y_bar);
d.u_hp=u_app(:)-state.u_bar;d.y_hp=d.y-state.y_bar;
state.u_hp_window(:,1:end-1)=state.u_hp_window(:,2:end);
state.u_hp_window(:,end)=d.u_hp;
state.window_count=min(p.excitation_window,state.window_count+1);
residual=d.y-state.alpha.*u_app(:)-state.F;
d.residual_jump=residual-state.residual_previous;
state.residual_previous=residual;
g=repmat(struct('pass',false,'reason',"",'energy',0,'rcond',0,'amplitude',0,'slow_tick',false),2,1);
for x=1:2
    g(x)=prototype.excitation_gate(x,d.u_hp(x),d.residual_jump(x),state,p);
    d.gate_exc(x)=g(x).pass;d.energy(x)=g(x).energy;d.rcond(x)=g(x).rcond;
end
slow_tick=mod(double(state.sample_index),p.N_alpha)==0;
if method=="B1"||p.disable_excitation,alpha_mask=repmat(quality.pass&&slow_tick&&state.window_count>=p.excitation_window,2,1);
else,alpha_mask=d.gate_exc&quality.pass&slow_tick;end
if p.freeze_alpha,alpha_mask(:)=false;end
for x=1:2
    if state.freeze_count(x)>p.long_freeze_cycles && ~p.disable_reacquire
        if d.gate_exc(x)&&quality.pass,state.good_window_count(x)=state.good_window_count(x)+1;else,state.good_window_count(x)=0;end
        if state.good_window_count(x)<p.reactivation_good_windows,alpha_mask(x)=false;end
        if state.good_window_count(x)==p.reactivation_good_windows
            state.reacquire_count(x)=state.reacquire_count(x)+1;
        end
    end
end
oldF=state.F;
if method=="RLS"
    [state,rd]=prototype.constrained_rls_update(state,d.y,u_app,d.gate_exc,quality.pass,p);
    d.alpha_update=rd.updated&d.gate_exc;d.projection_hit=rd.projection_hit;
    state.F_pred=state.F;alpha_mask=d.alpha_update;
else
    [state.alpha,d.projection_hit]=prototype.alpha_update(state.alpha,d.u_hp,d.y_hp, ...
        alpha_mask,quality.step_scale,p);
    d.alpha_update=alpha_mask;
    if method=="B1"
        state.F=original_F(:);state.F_pred=state.F;
    else
        [state.F,state.F_pred]=prototype.F_update(state.F,state.F_previous,d.y,u_app, ...
            state.alpha,repmat(quality.pass,2,1),method=="P"&&state.decision_gate_latched,p);
    end
end
state.F_previous=oldF;
state.projection_hits=state.projection_hits+double(d.projection_hit);
state.update_count=state.update_count+double(d.alpha_update);
for x=1:2
    if d.alpha_update(x)
        state.freeze_count(x)=0;state.status(x)="active";d.freeze_reason(x)="none";
    else
        state.freeze_count(x)=state.freeze_count(x)+1;
        if ~quality.pass,state.status(x)="frozen_s2";d.freeze_reason(x)=quality.reason;
        elseif abs(d.residual_jump(x))>p.residual_jump_max(x),state.status(x)="frozen_residual";d.freeze_reason(x)="residual_jump";
        elseif state.freeze_count(x)>p.long_freeze_cycles,state.status(x)="reacquire";d.freeze_reason(x)="reacquire_wait";
        elseif ~slow_tick,state.status(x)="active";d.freeze_reason(x)="not_slow_tick";
        else,state.status(x)="frozen_excitation";d.freeze_reason(x)=g(x).reason;end
    end
end
d.state=state.status;
end
