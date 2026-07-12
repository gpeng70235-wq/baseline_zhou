function y=predict_current(i,F,u,alpha,Ts),y=i+Ts*(F+alpha(:).*u);end
