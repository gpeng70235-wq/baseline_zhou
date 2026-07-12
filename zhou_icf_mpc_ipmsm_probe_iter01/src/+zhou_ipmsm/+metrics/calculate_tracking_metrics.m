function m=calculate_tracking_metrics(i,r),e=i-r;m.rmse_d=sqrt(mean(e(1,:).^2));m.rmse_q=sqrt(mean(e(2,:).^2));m.rmse=sqrt(mean(e(:).^2));end
