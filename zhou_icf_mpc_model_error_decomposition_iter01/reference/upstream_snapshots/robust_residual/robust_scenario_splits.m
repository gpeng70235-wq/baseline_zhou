function splits=robust_scenario_splits(project)
%ROBUST_SCENARIO_SPLITS Pre-registered complete-scenario split; no cycle shuffle.

template=make(project,"TEMPLATE","template",100,0,10,.005,1);
cal=repmat(template,0,1);val=repmat(template,0,1);test=repmat(template,0,1);
% Calibration nominal six conditions.
nom=[100 10 .005;100 20 .010;300 10 .020;300 20 .005;500 10 .010;500 20 .005];
for k=1:size(nom,1),cal(end+1)=make(project,"CAL",sprintf('cal_nom_%d',k),nom(k,1),0,nom(k,2),nom(k,3),1000+k);end %#ok<AGROW>
% Calibration single-parameter changes, one factor at a time.
defs={"Ld",.9;"Ld",1.1;"Lq",.9;"Lq",1.1;"Rs",.8;"Rs",1.2;"psi",.95;"psi",1.05};
for k=1:size(defs,1),s=make(project,"CAL",sprintf('cal_%s_%g',defs{k,1},defs{k,2}),300,0,20,.007,1100+k);s=setscale(s,defs{k,1},defs{k,2});cal(end+1)=s;end %#ok<AGROW>
for v=[46 48 50],s=make(project,"CAL",sprintf('cal_vdc_%g',v),500,0,20,.007,1200+v);s.dc_bus_V=v;cal(end+1)=s;end %#ok<AGROW>

% Validation negative-id family.
for speed=[100 300 500],for id=[0 -2 -4 -6],iq=sqrt(20^2-id^2);val(end+1)=make(project,"VAL",sprintf('val_negid_%d_%g',speed,id),speed,id,iq,.010,2000+speed-id);end,end %#ok<AGROW>
unseen=[200 15 .007;400 15 .012;300 18 .008;500 15 .015];
for k=1:size(unseen,1),val(end+1)=make(project,"VAL",sprintf('val_unseen_%d',k),unseen(k,1),0,unseen(k,2),unseen(k,3),2100+k);end %#ok<AGROW>
for dt=[0 2e-6 4e-6],s=make(project,"VAL",sprintf('val_deadtime_%gus',dt*1e6),300,0,20,.007,2200+round(dt*1e7));s.dead_time_s=dt;val(end+1)=s;end %#ok<AGROW>
s=make(project,"VAL","val_noise_0p05",300,0,20,.007,2301);s.measurement_noise_std_A=.05;val(end+1)=s;
for deg=[-1 1],s=make(project,"VAL",sprintf('val_angle_%+gdeg',deg),300,0,20,.007,2400+deg);s.angle_error_deg=deg;val(end+1)=s;end %#ok<AGROW>

% Independent test: combined mismatch, voltage, fast dynamics, negative id, unseen noise.
combo=[.9 1.1 1 1;1.1 .9 1 1;1 1 1.2 .95;1 1 .8 1.05];
for k=1:4,s=make(project,"TEST",sprintf('test_combo_%d',k),500,0,20,.005,3000+k);s.plant_Ld_scale=combo(k,1);s.plant_Lq_scale=combo(k,2);s.plant_Rs_scale=combo(k,3);s.plant_psi_f_scale=combo(k,4);test(end+1)=s;end %#ok<AGROW>
for v=[44 46 48 52],s=make(project,"TEST",sprintf('test_vdc_%g',v),500,0,20,.005,3100+v);s.dc_bus_V=v;test(end+1)=s;end %#ok<AGROW>
for speed=[300 500],for iq=[15 20],for ramp=[.003 .005 .007 .010],test(end+1)=make(project,"TEST",sprintf('test_dyn_%d_%g_%gms',speed,iq,1e3*ramp),speed,0,iq,ramp,3200+speed+round(1000*ramp)+iq);end,end,end %#ok<AGROW>
for row=[500 -2;500 -4;500 -6;300 -6].',speed=row(1);id=row(2);test(end+1)=make(project,"TEST",sprintf('test_high_negid_%d_%g',speed,id),speed,id,sqrt(20^2-id^2),.005,4000+speed-id);end %#ok<AGROW>
s=make(project,"TEST","test_transition_step_300",300,0,20,.003,5101);s.profile_type="two_step";test(end+1)=s;
s=make(project,"TEST","test_transition_step_500",500,0,20,.003,5102);s.profile_type="two_step";test(end+1)=s;
for seed=[6101 6102],s=make(project,"TEST",sprintf('test_unseen_noise_seed_%d',seed),500,0,20,.005,seed);s.measurement_noise_std_A=.05;test(end+1)=s;end %#ok<AGROW>

splits=struct('calibration',cal,'validation',val,'test',test);
end

function s=make(project,split,id,speed,idref,iqref,ramp,seed)
s=control_scenario(project);
switch upper(string(split)),case "CAL",split="calibration";case "VAL",split="validation";otherwise,split="test";end
s.split=split;s.scenario_id=string(id);s.name=string(id);s.speed_rpm=speed;
s.id_ref_A=idref;s.iq_ref_A=iqref;s.reference_ramp_s=ramp;s.random_seed=seed;
s.profile_type="ramp";s.measurement_noise_std_A=0;s.angle_error_deg=0;s.dead_time_s=0;
s.voltage_drop_V=0;s.current_step_time_s=.05;s.plant_Ld_scale=1;s.plant_Lq_scale=1;
s.plant_Rs_scale=1;s.plant_psi_f_scale=1;
end
function s=setscale(s,name,value)
switch string(name),case "Ld",s.plant_Ld_scale=value;case "Lq",s.plant_Lq_scale=value;case "Rs",s.plant_Rs_scale=value;case "psi",s.plant_psi_f_scale=value;end
end
