function m=calculate_constraint_metrics(d,legal),m.negative_duration_count=sum(d(:)<-1e-12);m.illegal_command_count=sum(~legal);end
