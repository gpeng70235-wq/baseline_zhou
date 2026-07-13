function matrix = experiment_A3_negative_id_matrix(project)
%EXPERIMENT_A3_NEGATIVE_ID_MATRIX Three conditions and four id references.

base=project.base; all_s=project.experiments;
scenarios=[all_s(1),all_s(3),all_s(6)];
scenarios(2).name='300rpm_medium_15A'; scenarios(2).iq_ref_A=base.medium_current_A;
ids=[0 -0.1*base.rated_current_A -0.2*base.rated_current_A ...
    -0.3*base.rated_current_A];
rows=cell(0,1); template=table();
for k=1:numel(scenarios)
    for id=ids
        s=scenarios(k); s.id_ref_A=id; s.motor_model="P1";
        s.alpha_mode="axis_specific"; s.F_estimator="algebraic_iter11";
        [row,~,~,ok]=zhou_validation.execute_ipmsm_case_safe( ...
            project,s,"negative_id",true,template);
        if ok, template=row; end
        rows{end+1}=row; %#ok<AGROW>
    end
end
matrix=vertcat(rows{:});
writetable(matrix,fullfile(project.root,'results','negative_id',project.run_id,'metrics.csv'));
writetable(matrix,fullfile(project.root,'results','summary','negative_id_matrix.csv'));
end
