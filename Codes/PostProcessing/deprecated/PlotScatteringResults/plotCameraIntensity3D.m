% /* Plot 3D scattering figures w/ geometry                              *\
% |                                                                       |
% |    This script should be called with plotCameraIntensity_starter.     |
% |    That script performs the input required by this code.              |
% |                                                                       |
% \*---------------------------------------------------------------------*/


% Detect colinearity / coplanarity in X, Y or Z
warning('off','MATLAB:scatteredInterpolant:InterpEmptyTri2DWarnId')
warning('off','MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId')
x=data.coords(:,1);
y=data.coords(:,2);
z=data.coords(:,3);
xlin = linspace(min(x),max(x),2);
ylin = linspace(min(y),max(y),2);
zlin = linspace(min(z),max(z),2);
[X,Y] = meshgrid(xlin,ylin);
f = scatteredInterpolant(x,y,z);
Z = f(X,Y);
if(all(size(Z)==0))
    % X or Y are linear. Cannot use this order.
    [Z,X] = meshgrid(zlin,xlin);
    f = scatteredInterpolant(z,x,y);
    Y = f(Z,X);
    if(all(size(Y)==0))
        % Z or X are linear. Cannot use this order.
        [Y,Z] = meshgrid(ylin,zlin);
        f = scatteredInterpolant(y,z,x);
        X = f(Y,Z);
        if(all(size(X)==0))
            % All three dimensions give the same problem. I.e., all points
            % are on a linear line in 3D space.
            error('All camera points lie on a linear line. This script cannot process that case.')
        else
            % X or Y were linear. Z or X were linear. But Z nor Y is
            % linear. So X must be linear.
            % We can use {y,z,x}.
            dimx = 2; dimy = 3; dimz = 1;
        end
    else
        % X or Y were linear, but Z nor X is linear. So Y is linear.
        % We can use {z,x,y}.
        dimx = 3; dimy = 1; dimz = 2;
    end
else
    % X nor Y is linear. We can use {x,y,z}.
    dimx = 1; dimy = 2; dimz = 3;
end
clear x y z f xlin ylin zlin X Y Z
warning('on','MATLAB:scatteredInterpolant:InterpEmptyTri2DWarnId')
warning('on','MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId')
% Use the index 'dimx' to refer to the x coordinate of the graph. Similarly
% for 'dimy' and 'dimz'.

% Order the data according to the dimx,dimy,dimz principle, such that the
% first index represents the "x" coordinate of the graph, etc
% Of course the label on the "x" coordinate of the graph will be "dimx".
khat = [khat(dimx), khat(dimy), khat(dimz)];
x=data.coords(:,dimx);
y=data.coords(:,dimy);
z=data.coords(:,dimz);

graphaxis={'x','y','z'};
    
% /*---------------------------------------------------------------------*\
% |                                                                       |
% |                   PLOTTING CODE. DO NOT TOUCH.                        |
% |                                                                       |
% \*---------------------------------------------------------------------*/

% Full 3D plot
%%%%%%%%%%%%%%

%plot(data.coords,data.int)

% surf(data.coords(:,dimx),data.coords(:,dimy),data.coords(:,dimz))

% % http://nl.mathworks.com/help/matlab/visualize/representing-a-matrix-as-a-surface.html
% xlin = linspace(min(x),max(x),33);
% ylin = linspace(min(y),max(y),33);
% [X,Y] = meshgrid(xlin,ylin);
% f = scatteredInterpolant(x,y,z);
% Z = f(X,Y);
% f = scatteredInterpolant(x,y,data.int);
% I = f(X,Y);
% 
% figure()
% % mesh(xlin,ylin,Z,I) % Interpolated graph
% plot3(x,y,z,'.','MarkerSize',pixelMarkerSize) % Exact points
% hold on
% surf(xlin,ylin,Z,I) % Interpolated graph
% hold off
% xlabel(graphaxis(dimx))
% ylabel(graphaxis(dimy))
% zlabel(graphaxis(dimz))

% clear x y z X Y Z f


% 2D representation...
%%%%%%%%%%%%%%%%%%%%%%

% Ignore z

% f = scatteredInterpolant(x,y,data.int);
% I = f(X,Y);
% 
% figure()
% surf(xlin,ylin,I)
% hold on
% plot3(x,y,data.int,'.','MarkerSize',pixelMarkerSize) % Exact points
% hold off
% xlabel(graphaxis(dimx))
% ylabel(graphaxis(dimy))
% zlabel(graphaxis(dimz))


% meshgrid method...
% http://nl.mathworks.com/help/matlab/math/interpolating-scattered-data.html

xlin = linspace(min(x),max(x),camSize(1)*interpPrecIncr); % Interpolation x range
ylin = linspace(min(y),max(y),camSize(2)*interpPrecIncr); % Interpolation y range
[xi,yi] = meshgrid(xlin,ylin);
zi = griddata(x,y,z,xi,yi); % Interpolation z range

% figure() % Color = z
% surf(xi,yi,zi);
% hold on
% plot3(x,y,z,'.','MarkerSize',pixelMarkerSize) % Exact points
% hold off
% xlabel(graphaxis(dimx))
% ylabel(graphaxis(dimy))
% zlabel(graphaxis(dimz))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Spheres, Camera & IPW - method 1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure() % Color = Intensity
inti = griddata(x,y,data.int,xi,yi); % Interpolate intensity. Note that z is not needed for a planar interpolation.
if(doLogScale); inti = log(inti); end
surf(xi,yi,zi,inti,'EdgeColor','none');
hold on
if(showPixelPoints); plot3(x,y,z,'.','MarkerSize',pixelMarkerSize); end % Exact points
hold off
xlabel(graphaxis(dimx))
ylabel(graphaxis(dimy))
zlabel(graphaxis(dimz))
if(doLogScale)
    title('Scattering Geometry')
else
    title('Scattering Geometry')
end
colormap jet
colorbar
hold on
h_spheres = plot3(data.spherePos(:,dimx),data.spherePos(:,dimy),data.spherePos(:,dimz),'.','MarkerSize',sphereMarkerSize); % Spheres
set(h_spheres,'Color',[0.8 0 0]);
clear h_spheres;
hold off

if(showIncidentPlane)
% Add the incident plane wave
f = @(x,y,z) khat(1)*x + khat(2)*y + khat(3)*z;
f_z = @(x,y,c) (c - khat(1)*x - khat(2)*y)/(khat(3)+eps(max(khat)));

minmax = zeros(3,2); % Index1 = xyz; Index2 = minmax
minmax(1,1) = min([x; data.spherePos(:,dimx)]);
minmax(1,2) = max([x; data.spherePos(:,dimx)]);
minmax(2,1) = min([y; data.spherePos(:,dimy)]);
minmax(2,2) = max([y; data.spherePos(:,dimy)]);
minmax(3,1) = min([z; data.spherePos(:,dimz)]);
minmax(3,2) = max([z; data.spherePos(:,dimz)]);
xlinIPW = linspace(minmax(1,1),minmax(1,2),2);
ylinIPW = linspace(minmax(2,1),minmax(2,2),2);
[xi,yi] = meshgrid(xlinIPW,ylinIPW);
hold on
khat_indices = (sign(-khat) - (sign(-khat) == 0) + 1 )/2 + 1;
c=f(minmax(1,khat_indices(1)),minmax(2,khat_indices(2)),minmax(3,khat_indices(3)));
h_IPW = surf(xi,yi,f_z(xi,yi,c));
set(h_IPW,'FaceColor',[0.99 0.99 0.9],'FaceAlpha',1);
clear h_IPW
hold off

% Vector %
scale_xyz = (minmax(:,2)-minmax(:,1))*0.1.*khat'; % "10%" of domain size
scale_xyz = norm(scale_xyz);
z_IPWvec = f_z(mean(mean(xi)),mean(mean(yi)),c);
IPWvec = [mean(mean(xi)) mean(mean(xi))+khat(1)*scale_xyz;...
    mean(mean(yi)) mean(mean(yi))+khat(2)*scale_xyz;...
    z_IPWvec z_IPWvec+khat(3)*scale_xyz];
clear scale_xyz z_IPWvec;

hold on
h_IPWvec = plot3(IPWvec(1,:), IPWvec(2,:), IPWvec(3,:)); % Vector in the direction of khat
hold off
set(h_IPWvec,'Color',[0.2 0.5 0.1]);
clear h_IPWvec;

end


caxis([min(min(min(inti))), max(max(max(inti)))+10*eps(max(max(inti)))]) % Colorbar should only refer to the intensity

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Spheres, Camera & IPW - method 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[xi,yi] = meshgrid(xlin,ylin);
zi = griddata(x,y,z,xi,yi);

figure() % Color = I
% inti = griddata(x,y,data.int,xi,yi,'nearest');
inti = griddata(x,y,data.int,xi,yi);
if(doLogScale); inti = log(inti); end
surf(xi,yi,zi,inti,'EdgeColor','none');
hold on
if(showPixelPoints); plot3(x,y,z,'.','MarkerSize',pixelMarkerSize); end % Exact points
hold off
xlabel(graphaxis(dimx))
ylabel(graphaxis(dimy))
zlabel(graphaxis(dimz))
if(doLogScale)
    title('Scattering Geometry')
else
    title('Scattering Geometry')
end
colormap jet
colorbar
hold on
h_spheres = plot3(data.spherePos(:,dimx),data.spherePos(:,dimy),data.spherePos(:,dimz),'.','MarkerSize',sphereMarkerSize); % Spheres
set(h_spheres,'Color',[0.8 0 0]);
clear h_spheres;
hold off




%%% Add the incident plane wave %%%
% Plane %
f = @(x,y,z) khat(1)*x + khat(2)*y + khat(3)*z;
f_x = @(y,z,c) (c - khat(2)*y - khat(3)*z)/(khat(1)+eps(max(khat)));
f_y = @(x,z,c) (c - khat(1)*x - khat(3)*z)/(khat(2)+eps(max(khat)));
f_z = @(x,y,c) (c - khat(1)*x - khat(2)*y)/(khat(3)+eps(max(khat)));

khat_indices = (sign(-khat) - (sign(-khat) == 0) + 1 )/2 + 1;
minmax = zeros(3,2); % Index1 = xyz; Index2 = minmax
minmax(1,1) = min([data.coords(:,dimx); data.spherePos(:,dimx)]);
minmax(1,2) = max([data.coords(:,dimx); data.spherePos(:,dimx)]);
minmax(2,1) = min([data.coords(:,dimy); data.spherePos(:,dimy)]);
minmax(2,2) = max([data.coords(:,dimy); data.spherePos(:,dimy)]);
minmax(3,1) = min([data.coords(:,dimz); data.spherePos(:,dimz)]);
minmax(3,2) = max([data.coords(:,dimz); data.spherePos(:,dimz)]);
delta = (minmax(:,2)-minmax(:,1))/10;
if(khat(1)==0)
    xlin = linspace(minmax(1,1),minmax(1,2),2);
else
    xlin = linspace(minmax(1,khat_indices(1))-sign(khat(1))*delta(1),minmax(1,khat_indices(1)),2);
end
if(khat(2)==0)
    ylin = linspace(minmax(2,1),minmax(2,2),2);
else
    ylin = linspace(minmax(2,khat_indices(2))-sign(khat(2))*delta(2),minmax(2,khat_indices(2)),2);
end
khat_nmaxs = (abs(khat) ~= max(abs(khat)));
c = f(minmax(1,khat_indices(1))-khat_nmaxs(1)*sign(khat(1))*delta(1), ...
    minmax(2,khat_indices(2))-khat_nmaxs(2)*sign(khat(2))*delta(2), ...
    minmax(3,khat_indices(3))-khat_nmaxs(3)*sign(khat(3))*delta(3));
[xi,yi] = meshgrid(xlin,ylin);

zi = f_z(xi,yi,c);
boolMat = zi<minmax(3,1)-delta(3);
if(any(any(boolMat))) % Horrible out of bounds guess above... Cut it.
    zi(boolMat) = minmax(3,1)-delta(3);
    if(all(boolMat(:,1)) || all(boolMat(:,2)))
        % Recompute xi
        xi = f_x(yi,zi,c);
    else
        % Recompute yi
        yi = f_y(xi,zi,c);
    end
end
boolMat = zi>minmax(3,2)+delta(3);
if(any(any(boolMat))) % Horrible out of bounds guess above... Cut it.
    zi(boolMat) = minmax(3,2)+delta(3);
    if(all(boolMat(:,1)) || all(boolMat(:,2)))
        % Recompute xi
        xi = f_x(yi,zi,c);
    else
        % Recompute yi
        yi = f_y(xi,zi,c);
    end
end
clear boolMat

% Vector %
scale_xyz = (minmax(:,2)-minmax(:,1))*0.1.*khat'; % "10%" of domain size
scale_xyz = norm(scale_xyz);
IPWvec = [mean(mean(xi)) mean(mean(xi))+khat(1)*scale_xyz;...
    mean(mean(yi)) mean(mean(yi))+khat(2)*scale_xyz;...
    mean(mean(zi)) mean(mean(zi))+khat(3)*scale_xyz];
clear scale_xyz

hold on
h_IPW = surf(xi,yi,zi); % Surface representing the IPW
h_IPWvec = plot3(IPWvec(1,:), IPWvec(2,:), IPWvec(3,:)); % Vector in the direction of khat
hold off
set(h_IPW,'FaceColor',[0.99 0.99 0.9],'FaceAlpha',1);
set(h_IPWvec,'Color',[0.2 0.5 0.1]);
clear h_IPW h_IPWvec IPWvec

caxis([min(min(inti)), max(max(inti))+10*eps(max(max(inti)))]) % Colorbar should only refer to the intensity






% /*---------------------------------------------------------------------*\
% |                                                                       |
% |                                CLEAN-UP                               |
% |                                                                       |
% \*---------------------------------------------------------------------*/



clear x y z f f_x f_y f_z delta dimx dimy dimz c graphaxis
clear inti khat_indices khat_nmaxs minmax xi yi zi xlin ylin xlinIPW ylinIPW