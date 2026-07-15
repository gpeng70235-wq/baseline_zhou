function result = rectangle_hexagon_intersection(rect,vectors,tolerance)
%RECTANGLE_HEXAGON_INTERSECTION Clip the Zhou dq rectangle against H.
% polygon_ab/polygon_dq contain unique vertices without a repeated endpoint.

arguments
    rect struct
    vectors struct
    tolerance (1,1) double {mustBeFinite,mustBeNonnegative} = 1e-10
end
required = {'corners_ab','theta','center_dq','half_dq'};
for k=1:numel(required)
    assert(isfield(rect,required{k}),'ZhouFeasibility:InvalidRectangle', ...
        'rect.%s is required.',required{k});
end
assert(isequal(size(rect.corners_ab),[4,2]), ...
    'ZhouFeasibility:InvalidRectangle','rect.corners_ab must be 4-by-2.');

polygon = order_ccw(double(rect.corners_ab),tolerance);
hexagon = hex_vertices(vectors);
for k=1:6
    j=mod(k,6)+1;
    polygon=clip_to_left_halfspace(polygon,hexagon(k,:),hexagon(j,:),tolerance);
    if isempty(polygon), break; end
end
polygon=canonical_polygon(polygon,tolerance);
if isempty(polygon)
    polygon_dq=zeros(0,2); area_V2=0;
else
    c=cos(rect.theta);s=sin(rect.theta);
    polygon_dq=([c,s;-s,c]*polygon.').';
    area_V2=polygon_area(polygon);
end

result=struct();
result.polygon_ab=polygon;
result.polygon_dq=polygon_dq;
result.area_V2=area_V2;
result.nonempty=~isempty(polygon);
result.vertex_count=size(polygon,1);
result.is_degenerate=result.nonempty && area_V2<=tolerance^2;
result.rectangle_ab=order_ccw(double(rect.corners_ab),tolerance);
result.hexagon_ab=hexagon;
result.theta_rad=rect.theta;
result.tolerance_V=tolerance;
if result.nonempty
    inside_h=false(size(polygon,1),1);
    for k=1:size(polygon,1)
        inside_h(k)=zhou_feasibility.point_in_hexagon(polygon(k,:),vectors,10*tolerance);
    end
    q=(polygon_dq-rect.center_dq(:).')./rect.half_dq(:).';
    result.vertices_inside_hexagon=all(inside_h);
    result.vertices_inside_rectangle=all(abs(q)<=1+10*tolerance,'all');
else
    result.vertices_inside_hexagon=true;
    result.vertices_inside_rectangle=true;
end
end

function out=clip_to_left_halfspace(poly,a,b,tol)
if isempty(poly),out=zeros(0,2);return;end
out=zeros(0,2); edge=b-a;edge_length=norm(edge);
assert(edge_length>0,'ZhouFeasibility:DegenerateHexagon', ...
    'Hexagon clipping edges must be nonzero.');
for i=1:size(poly,1)
    previous=poly(mod(i-2,size(poly,1))+1,:);
    current=poly(i,:);
    % Divide by edge length so fp/fc and tol all have voltage units.
    fp=cross2(edge,previous-a)/edge_length;
    fc=cross2(edge,current-a)/edge_length;
    inp=fp>=-tol;inc=fc>=-tol;
    if inc
        if ~inp,out(end+1,:)=segment_boundary_intersection(previous,current,fp,fc);end %#ok<AGROW>
        out(end+1,:)=current; %#ok<AGROW>
    elseif inp
        out(end+1,:)=segment_boundary_intersection(previous,current,fp,fc); %#ok<AGROW>
    end
end
out=remove_duplicates(out,tol);
end

function p=segment_boundary_intersection(a,b,fa,fb)
den=fa-fb;
if abs(den)<=eps(max([1,abs(fa),abs(fb)])),t=0.5;else,t=fa/den;end
t=min(1,max(0,t)); % bounds only the interpolation roundoff, not a control duty
p=a+t*(b-a);
end

function p=canonical_polygon(p,tol)
p=remove_duplicates(p,tol);
if size(p,1)>=3
    signed=0.5*sum(p(:,1).*p([2:end,1],2)-p([2:end,1],1).*p(:,2));
    if signed<0,p=flipud(p);end
end
if size(p,1)>=2
    [~,order]=sortrows(p,[1,2]);start=order(1);
    p=p([start:end,1:start-1],:);
end
end

function p=remove_duplicates(p,tol)
if isempty(p),p=zeros(0,2);return;end
keep=true(size(p,1),1);
for i=2:size(p,1)
    if any(vecnorm(p(1:i-1,:)-p(i,:),2,2)<=tol),keep(i)=false;end
end
p=p(keep,:);
end

function p=order_ccw(p,tol)
p=remove_duplicates(p,tol);center=mean(p,1);
[~,idx]=sort(atan2(p(:,2)-center(2),p(:,1)-center(1)));p=p(idx,:);
p=canonical_polygon(p,tol);
end

function h=hex_vertices(vectors)
h=double(vectors.ab_V(2:7,:));center=mean(h,1);
[~,idx]=sort(mod(atan2(h(:,2)-center(2),h(:,1)-center(1)),2*pi));h=h(idx,:);
end
function z=cross2(a,b),z=a(1)*b(2)-a(2)*b(1);end
function a=polygon_area(p)
if size(p,1)<3,a=0;else,a=0.5*abs(sum(p(:,1).*p([2:end,1],2)-p([2:end,1],1).*p(:,2)));end
end
