function result = project_point_to_polygon(point,polygon,tolerance)
%PROJECT_POINT_TO_POLYGON Exact Euclidean projection onto a convex polygon.
% The coordinates may be physical or normalized; the same coordinate
% system is used for the returned squared distance.

arguments
    point (1,2) double {mustBeFinite}
    polygon (:,2) double {mustBeFinite}
    tolerance (1,1) double {mustBeFinite,mustBeNonnegative} = 1e-12
end
assert(~isempty(polygon),'ZhouFeasibility:EmptyPolygon', ...
    'Projection onto an empty polygon is undefined.');
polygon=remove_closure_and_duplicates(polygon,tolerance);
n=size(polygon,1);
inside=is_inside_convex(point,polygon,tolerance);
if inside
    projected=point;distance2=0;edge_index=0;edge_fraction=NaN;
end

if n==1
    candidates=polygon;fractions=0;
elseif n==2
    [c,t]=segment_projection(point,polygon(1,:),polygon(2,:));
    candidates=c;fractions=t;
else
    candidates=zeros(n,2);fractions=zeros(n,1);
    for k=1:n
        [c,t]=segment_projection(point,polygon(k,:),polygon(mod(k,n)+1,:));
        candidates(k,:)=c;fractions(k)=t;
    end
end
candidate_distance2=sum((candidates-point).^2,2);
if ~inside
    [distance2,edge_index]=min(candidate_distance2);
    projected=candidates(edge_index,:);edge_fraction=fractions(edge_index);
end

result=struct();
result.point=projected;
result.projected_point=projected;
result.distance2=distance2;
result.distance=sqrt(distance2);
result.input_inside=inside;
result.edge_index=edge_index;
result.edge_fraction=edge_fraction;
result.candidate_points=candidates;
result.candidate_distance2=candidate_distance2;
result.polygon=polygon;
result.tolerance=tolerance;
end

function inside=is_inside_convex(p,poly,tol)
n=size(poly,1);
if n==1,inside=norm(p-poly(1,:))<=tol;return;end
if n==2
    [q,~]=segment_projection(p,poly(1,:),poly(2,:));inside=norm(p-q)<=tol;return
end
crosses=zeros(n,1);
for k=1:n
    a=poly(k,:);b=poly(mod(k,n)+1,:);e=b-a;
    crosses(k)=e(1)*(p(2)-a(2))-e(2)*(p(1)-a(1));
end
inside=all(crosses>=-tol)||all(crosses<=tol);
end
function [q,t]=segment_projection(p,a,b)
e=b-a;den=dot(e,e);
if den==0,t=0;else,t=dot(p-a,e)/den;t=min(1,max(0,t));end
q=a+t*e;
end
function p=remove_closure_and_duplicates(p,tol)
if size(p,1)>1 && norm(p(1,:)-p(end,:))<=tol,p(end,:)=[];end
keep=true(size(p,1),1);
for k=2:size(p,1)
    if any(vecnorm(p(1:k-1,:)-p(k,:),2,2)<=tol),keep(k)=false;end
end
p=p(keep,:);
end
