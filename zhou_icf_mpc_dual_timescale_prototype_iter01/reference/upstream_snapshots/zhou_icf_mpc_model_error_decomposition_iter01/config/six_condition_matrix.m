function scenarios=six_condition_matrix(project)
%SIX_CONDITION_MATRIX Formal six P1 conditions before paired P0 expansion.
speeds=[100 100 300 300 500 500];currents=[10 20 10 20 10 20];
scenarios=repmat(control_scenario(project),1,6);
for k=1:6
    scenarios(k).speed_rpm=speeds(k);scenarios(k).iq_ref_A=currents(k);
    scenarios(k).name=sprintf('%drpm_%gA',speeds(k),currents(k));
end
end
