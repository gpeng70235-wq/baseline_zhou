function export_trace_plot(trace, plot_directory, name)
%EXPORT_TRACE_PLOT Standard current, torque, and applied-Case diagnostic.
figure_handle = figure('Visible','off','Color','w','Position',[100 100 900 720]);
tiledlayout(3,1,'TileSpacing','compact');
nexttile;
plot(trace.time_s,trace.current(1,:),'LineWidth',1); hold on;
plot(trace.time_s,trace.current(2,:),'LineWidth',1);
plot(trace.time_s,trace.reference_dq(1,:),'--');
plot(trace.time_s,trace.reference_dq(2,:),'--');
ylabel('current (A)'); legend('i_d','i_q','i_d^*','i_q^*','Location','best'); grid on;
nexttile;
plot(trace.time_s,trace.torque,'LineWidth',1); hold on;
plot(trace.time_s,trace.reluctance_torque,'LineWidth',1);
ylabel('torque (N m)'); legend('total','reluctance','Location','best'); grid on;
nexttile;
stairs(trace.time_s,trace.case_id,'LineWidth',1);
ylim([0.5 3.5]); yticks(1:3); ylabel('applied Case'); xlabel('time (s)'); grid on;
sgtitle(strrep(name,'_','\_'));
exportgraphics(figure_handle,fullfile(plot_directory,'trace.png'),'Resolution',160);
close(figure_handle);
end
