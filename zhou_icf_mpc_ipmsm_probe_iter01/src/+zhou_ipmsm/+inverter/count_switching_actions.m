function n=count_switching_actions(states),if size(states,1)<2,n=0;else,n=sum(abs(diff(states,1,1)),'all');end,end
