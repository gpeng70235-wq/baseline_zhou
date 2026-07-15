function R=residual_correlations(T)
%RESIDUAL_CORRELATIONS Descriptive P0 associations; never causal attribution.
groups=[struct('name',"ALL",'mask',true(height(T),1));arrayfun(@(x)struct('name',x,'mask',T.case_id==x),unique(T.case_id,'stable'))];
windows=["all","dynamic","steady"];
numericNames=["id","iq","id_ref","iq_ref","speed_rpm","electrical_angle", ...
    "sin_electrical_angle","cos_electrical_angle","Fd_original","Fq_original", ...
    "F_estimation_error_d","F_estimation_error_q","F_time_increment_d","F_time_increment_q", ...
    "alpha_error_d","alpha_error_q","Ld_relative_mismatch","Lq_relative_mismatch", ...
    "voltage_utilization","distance_to_Jd_boundary","distance_to_Jq_boundary","reference_rate_A_s"];
values={T.id,T.iq,T.id_ref,T.iq_ref,T.speed_rpm,T.electrical_angle,sin(T.electrical_angle),cos(T.electrical_angle), ...
    T.Fd_original,T.Fq_original,T.delta_Fd,T.delta_Fq,T.delta_Fd_sample,T.delta_Fq_sample, ...
    T.alpha_d_error,T.alpha_q_error,(T.Ld_actual-T.Ld_controller)./T.Ld_controller, ...
    (T.Lq_actual-T.Lq_controller)./T.Lq_controller,T.voltage_utilization,T.distance_to_Jd_boundary, ...
    T.distance_to_Jq_boundary,T.reference_rate_A_s};
rows=repmat(template(),0,1);
for g=1:numel(groups)
    for window=windows
        mask=groups(g).mask;if window~="all",mask=mask&T.phase==window;end
        for axis=["d","q"]
            if axis=="d",res=T.ed_P0;else,res=T.eq_P0;end
            for j=1:numel(numericNames)
                [pearson,spearman,slope,n,bestLag,bestCorr]=association(res(mask),values{j}(mask),any(contains(numericNames(j),["F_","alpha_"])));
                r=template();r.cohort=groups(g).name;r.window_type=window;r.axis=axis;r.predictor="P0";
                r.residual_name="e_P0_"+axis;r.explanatory_variable=numericNames(j);r.variable_type="numeric";
                r.sample_count=n;r.pearson_r=pearson;r.spearman_r=spearman;r.linear_slope=slope;
                r.best_lag_samples=bestLag;r.best_lag_s=bestLag*1e-4;r.best_abs_cross_correlation=bestCorr;
                x=res(mask);v=values{j}(mask);r.residual_rms_A=rmsv(x);r.variable_std=std(v,'omitnan');
                r.valid=n>=10&&isfinite(pearson);if ~r.valid,r.invalid_reason="insufficient samples or zero variance";end
                rows(end+1)=r; %#ok<AGROW>
            end
            rows(end+1)=categorical_row(groups(g).name,window,axis,res(mask),T.S2_triggered(mask),"S2_triggered","binary"); %#ok<AGROW>
            rows(end+1)=categorical_row(groups(g).name,window,axis,res(mask),T.vector_mode(mask),"vector_mode","categorical"); %#ok<AGROW>
        end
    end
end
R=struct2table(rows,'AsArray',true);
end

function [p,s,b,n,bestLag,bestAbs]=association(y,x,scanLag)
keep=isfinite(x)&isfinite(y);x=x(keep);y=y(keep);n=numel(x);p=NaN;s=NaN;b=NaN;bestLag=NaN;bestAbs=NaN;
if n<3||std(x)==0||std(y)==0,return,end
p=pearson(x,y);s=pearson(tiedrank_local(x),tiedrank_local(y));b=sum((x-mean(x)).*(y-mean(y)))/sum((x-mean(x)).^2);
if scanLag
    bestAbs=-Inf;bestLag=0;
    for lag=-10:10
        if lag<0,xx=x(1-lag:end);yy=y(1:end+lag);elseif lag>0,xx=x(1:end-lag);yy=y(1+lag:end);else,xx=x;yy=y;end
        q=pearson(xx,yy);if isfinite(q)&&abs(q)>bestAbs,bestAbs=abs(q);bestLag=lag;end
    end
    if bestAbs==-Inf,bestAbs=NaN;bestLag=NaN;end
end
end

function value=pearson(x,y)
x=x(:)-mean(x);y=y(:)-mean(y);den=sqrt(sum(x.^2)*sum(y.^2));if den==0,value=NaN;else,value=sum(x.*y)/den;end
end

function r=tiedrank_local(x)
[v,order]=sort(x(:));r=zeros(size(x(:)));start=1;
while start<=numel(v),last=start;while last<numel(v)&&v(last+1)==v(start),last=last+1;end;r(order(start:last))=(start+last)/2;start=last+1;end
end

function r=categorical_row(cohort,window,axis,res,group,name,type)
r=template();r.cohort=cohort;r.window_type=window;r.axis=axis;r.predictor="P0";r.residual_name="e_P0_"+axis;
r.explanatory_variable=name;r.variable_type=type;keep=isfinite(res);res=res(keep);group=group(keep);r.sample_count=numel(res);
r.residual_rms_A=rmsv(res);r.variable_std=NaN;r.best_lag_samples=NaN;r.best_lag_s=NaN;r.best_abs_cross_correlation=NaN;
if type=="binary"
    group=logical(group);if any(group)&&any(~group),r.categorical_effect=rmsv(res(group))-rmsv(res(~group));r.valid=true;else,r.invalid_reason="one binary level absent";end
else
    levels=unique(string(group));grand=mean(res);between=0;total=sum((res-grand).^2);
    for level=levels.',z=res(string(group)==level);between=between+numel(z)*(mean(z)-grand)^2;end
    if numel(levels)>=2&&total>0,r.categorical_effect=between/total;r.valid=true;else,r.invalid_reason="fewer than two levels or zero variance";end
end
end

function r=template()
r=struct('cohort',"",'window_type',"",'axis',"",'predictor',"P0",'residual_name',"", ...
    'explanatory_variable',"",'variable_type',"",'sample_count',0,'pearson_r',NaN,'spearman_r',NaN, ...
    'linear_slope',NaN,'best_lag_samples',NaN,'best_lag_s',NaN,'best_abs_cross_correlation',NaN, ...
    'residual_rms_A',NaN,'variable_std',NaN,'categorical_effect',NaN,'valid',false,'invalid_reason',"");
end

function value=rmsv(x),x=x(isfinite(x));if isempty(x),value=NaN;else,value=sqrt(mean(x.^2));end,end
