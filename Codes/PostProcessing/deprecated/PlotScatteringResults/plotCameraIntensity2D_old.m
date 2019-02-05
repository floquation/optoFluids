% /*---------------------------------------------------------------------*\
% |                                                                       |
% |    This script should be called with plotCameraIntensity_starter.     |
% |    That script performs the input required by this code.              |
% |                                                                       |
% \*---------------------------------------------------------------------*/





ahat = a/norm(a);
bhat = b/norm(b);
ahat(abs(ahat)<=2*max(eps(ahat)))=0;
bhat(abs(bhat)<=2*max(eps(bhat)))=0;
alabel = strcat('a = [',num2str(ahat),']');
blabel = strcat('b = [',num2str(bhat),']');
clear ahat bhat

% %%%%%%
% % Now plot the intensity in a,b-coordinates.
% %%%%%%%% 1: Without any interpolation whatsoever; 3D
% figure()
% A = reshape(data2D.coords(:,1),camSize);
% B = reshape(data2D.coords(:,2),camSize);
% inti = reshape(data.int,camSize);
% surf(A,B,inti)
% xlabel(alabel)
% ylabel(blabel)
% zlabel('intensity')
% title('intensity profile on the camera')
% 
% hold on
% plot3(data2D.coords(:,1),data2D.coords(:,2),data.int,'.','MarkerSize',pixelMarkerSize) % Exact points
% hold off
% colormap(jet(1000))
% colorbar
% % shading interp;


%%%%%%
% Now plot the intensity in a,b-coordinates.
%%%%%%%% 1a: Without any interpolation whatsoever; 2D
%%%%%%%%     pcolor and hack the last element in
shift = 1./(2*(camSize-1));
data2D.coords_shifted(:,1) = data2D.coords(:,1) - shift(1);
data2D.coords_shifted(:,2) = data2D.coords(:,2) - shift(2);
figure()
A = reshape(data2D.coords_shifted(:,1),camSize);
B = reshape(data2D.coords_shifted(:,2),camSize);
A = [A; 2*A(end,:)-A(end-1,:)]; A = [A, 2*A(:,end)-A(:,end-1)];
B = [B; 2*B(end,:)-B(end-1,:)]; B = [B, 2*B(:,end)-B(:,end-1)];
inti = reshape(data.int,camSize);
inti = [inti; inti(end,:)]; inti = [inti, inti(:,end)];
if(doLogScale); inti = reallog(abs(inti)); end
pcolor(A,B,inti)
xlabel(alabel)
ylabel(blabel)
% zlabel('intensity')
% title('intensity profile on the camera, using duplicate data point at boundary')
if(doLogScale)
    title('log(intensity profile) on the camera''s pixels - hacked pcolor')
else
    title('intensity profile on the camera''s pixels - hacked pcolor')
end

set(gca, 'XTick', A(:,1)+shift(1), 'XTickLabel', (A(:,1)')+shift(1));
set(gca, 'YTick', B(1,:)+shift(2), 'YTickLabel', (B(1,:)')+shift(2));

hold on
if(showPixelPoints); plot3(data2D.coords(:,1),data2D.coords(:,2),data.int,'.','MarkerSize',pixelMarkerSize); end % Exact points
hold off
colormap(jet(1000))
colorbar
% shading interp;


%%%%%%
% Now plot the intensity in a,b-coordinates.
%%%%%%%% 1b: Without any interpolation whatsoever; 2D
%%%%%%%%     imagesc
% figure()
% inti = reshape(data.int,camSize);
% imagesc(data2D.coords(:,1),flipud(data2D.coords(:,2)),inti')
% xlabel(alabel)
% ylabel(blabel)
% zlabel('intensity')
% title('intensity profile on the camera')
% 
% hold on
% plot3(data2D.coords(:,1),data2D.coords(:,2),data.int,'.','MarkerSize',pixelMarkerSize) % Exact points
% hold off
% colormap(jet(1000))
% colorbar
% % shading interp;


figure()
A = reshape(data2D.coords(:,1),camSize);
B = reshape(data2D.coords(:,2),camSize);
inti = reshape(data.int,camSize);
if(doLogScale); inti = reallog(abs(inti)); end
imagesc(A(:,1),B(1,:),flipud(inti'))
xlabel(alabel)
ylabel(blabel)
% zlabel('intensity')
title('intensity profile on the camera''s pixels - imagesc')
if(doLogScale)
    title('log(intensity profile) on the camera''s pixels - imagesc')
else
    title('intensity profile on the camera''s pixels - imagesc')
end

set(gca, 'XTick', A(:,1), 'XTickLabel', (A(:,1)'));
set(gca, 'YTick', B(1,:), 'YTickLabel', flipud(B(1,:)'));

hold on
if(showPixelPoints); plot3(data2D.coords(:,1),data2D.coords(:,2),data.int,'.','MarkerSize',pixelMarkerSize); end % Exact points
hold off
colormap(jet(1000))
colorbar
% shading interp



% %%%%%%
% % Now plot the intensity in a,b-coordinates.
% %%%%%%%% 1c: Without any interpolation whatsoever; 2D; pcolor
% figure()
% A = reshape(data2D.coords(:,1),camSize);
% B = reshape(data2D.coords(:,2),camSize);
% inti = reshape(data.int,camSize);
% pcolor(A,B,inti)
% xlabel(alabel)
% ylabel(blabel)
% zlabel('intensity')
% title('intensity profile on the camera')
% 
% hold on
% plot3(data2D.coords(:,1),data2D.coords(:,2),data.int,'.','MarkerSize',pixelMarkerSize) % Exact points
% hold off
% colormap(jet(1000))
% colorbar
% % shading interp;


% %%%%%%
% % Now plot the intensity in a,b-coordinates.
% %%%%%%%% 2: Interpolated; 3D
% figure()
% alin = linspace(0,1,ceil(40*sqrt(size(data.coords,1)))); % Interpolation a range
% blin = linspace(0,1,ceil(40*sqrt(size(data.coords,1)))); % Interpolation a range
% [A, B] = meshgrid(alin,blin);
% inti = griddata(data2D.coords(:,1),data2D.coords(:,2),data.int,A,B); % Interpolate intensity.
% surf(alin,blin,inti,'EdgeColor','none')
% xlabel(alabel)
% ylabel(blabel)
% zlabel('intensity')
% title('intensity profile on the camera')
% 
% hold on
% plot3(data2D.coords(:,1),data2D.coords(:,2),data.int,'.','MarkerSize',pixelMarkerSize) % Exact points
% hold off
% colormap(jet(1000))
% colorbar

%%%%%%
% Now plot the intensity in a,b-coordinates.
%%%%%%%% 2:  Interpolated; 3D
%%%%%%%%     surf and hack the last element in (because Matlab does not
%%%%%%%%      plot centered, but left-aligned.)
alin = linspace(0,1,camSize(1)*interpPrecIncr); % Interpolation a range
blin = linspace(0,1,camSize(2)*interpPrecIncr); % Interpolation a range
shift = 1./(2*([length(alin) length(blin)]-1)); % = half distance between subsequent points, potentionally different for a and b.
% alin = alin-shift(1);
% blin = blin-shift(1);
% alin = [2*alin(1)-alin(2), alin]; % Hack new column in (front)
% blin = [2*blin(1)-blin(2), blin]; % Hack new column in (front)
[A, B] = meshgrid(alin,blin);
figure()
inti = griddata(data2D.coords(:,1),data2D.coords(:,2),data.int,A,B); % Interpolate intensity.
% A = [A; 2*A(end,:)-A(end-1,:)]; A = [A, 2*A(:,end)-A(:,end-1)]; % Hack new row/column in (back)
% B = [B; 2*B(end,:)-B(end-1,:)]; B = [B, 2*B(:,end)-B(:,end-1)]; % Hack new row/column in (back)
alin = [alin, 2*alin(end)-alin(end-1)]; % Hack new column in (back)
blin = [blin, 2*blin(end)-blin(end-1)]; % Hack new column in (back)
alin = alin-shift(1);
blin = blin-shift(2);
% A = [2*A(1,:)-A(2,:);A]; A = [2*A(:,1)-A(:,2), A]; % Hack new row/column in (front)
% B = [2*B(1,:)-B(2,:); B]; B = [2*B(:,1)-B(:,2), B]; % Hack new row/column in (front)
inti = [inti; 2*inti(end,:)-inti(end-1,:)]; inti = [inti, 2*inti(:,end)-inti(:,end-1)]; % Hack new row/column in (back)
% inti = [2*inti(1,:)-inti(2,:); inti]; inti = [2*inti(:,1)-inti(:,2), inti]; % Hack new row/column in (front)
if(doLogScale); inti = reallog(abs(inti)); end
surf(alin,blin,inti,'EdgeColor','none')
xlabel('a')
ylabel('b')
if(doLogScale)
    zlabel('log(intensity)')
else
    zlabel('intensity')
end
title('intensity profile on the camera')

% set(gca, 'XTick', alin+shift(1), 'XTickLabel', alin+shift(1));
% set(gca, 'YTick', blin+shift(2), 'YTickLabel', blin+shift(2));

hold on
if(showPixelPoints); plot3(data2D.coords(:,1),data2D.coords(:,2),data.int,'.','MarkerSize',pixelMarkerSize); end % Exact points
hold off
colormap(jet(1000))
colorbar

axis([min(alin) max(alin), min(blin) max(blin), min(min(inti(1:end-1,1:end-1))), max(max(inti(1:end-1,1:end-1)))+10*eps(max(max(inti)))])
caxis([min(min(inti(1:end-1,1:end-1))), max(max(inti(1:end-1,1:end-1)))+10*eps(max(max(inti)))])

%%%%%%
% Now plot the intensity in a,b-coordinates.
%%%%%%%% 3:  Interpolated; 2D
%%%%%%%%     Same as (2), but now eagle view: view(2)

% inti(end/2:3*end/4,end/2:3*end/4)=-18; % TEST
% inti(:,end-2:end)=-25; % TEST
% inti(end-2:end,:)=-25; % TEST

% 64-bit map:
figure()
surf(alin,blin,inti,'EdgeColor','none')
xlabel(alabel)
ylabel(blabel)
if(doLogScale)
    zlabel('log(intensity)')
    mytitle=strcat('log(intensity) profile on the camera: ',caseNameGraph);
else
    zlabel('intensity')
    mytitle=strcat('intensity profile on the camera: ',caseNameGraph);
end
title(mytitle)
colormap(jet(64))
colorbar

axis([min(alin) max(alin), min(blin) max(blin), min(min(inti(1:end,1:end))), max(max(inti(1:end,1:end)))+10*eps(max(max(inti)))])
caxis([min(min(inti(1:end-1,1:end-1))), max(max(inti(1:end-1,1:end-1)))+10*eps(max(max(inti)))])
view(2)

% Smoothed:
figure()
surf(alin,blin,inti,'EdgeColor','none')
xlabel(alabel)
ylabel(blabel)
if(doLogScale)
    zlabel('log(intensity)')
    mytitle=strcat('log(intensity) profile on the camera (smoothed): ',caseNameGraph);
else
    zlabel('intensity')
    mytitle=strcat('intensity profile on the camera (smoothed): ',caseNameGraph);
end
title(mytitle)
colormap(jet(1000))
colorbar

axis([min(alin) max(alin), min(blin) max(blin), min(min(inti(1:end,1:end))), max(max(inti(1:end,1:end)))+10*eps(max(max(inti)))])
caxis([min(min(inti(1:end-1,1:end-1))), max(max(inti(1:end-1,1:end-1)))+10*eps(max(max(inti)))])
view(2)


%%%%%%
% Now plot the intensity in a,b-coordinates, but as a 2D figure
%%%%%%%% 4:  Interpolated; really 2D

% 1000-bit map:
fighandle2D = figure();
pcolor(alin,blin,inti)
xlabel(alabel)
ylabel(blabel)
if(doLogScale)
    mytitle=strcat('log(intensity) profile on the camera (smoothed): ',caseNameGraph);
else
    mytitle=strcat('intensity profile on the camera (smoothed): ',caseNameGraph);
end
title(mytitle)
colormap(jet(1000))
colorbar

shading('interp') % Fixes a graphics issue

axis([min(alin) max(alin), min(blin) max(blin)])
caxis([min(min(inti(1:end-1,1:end-1))), max(max(inti(1:end-1,1:end-1)))+10*eps(max(max(inti)))])

% set(gcf, 'Renderer', 'zbuffer') % Otherwise a black screen is saved 'for some reason'.
% set(gcf, 'Renderer', 'painters'); 
    
% saveas(gcf,'test.png')


% Circles for Airy plots
if(showAiryCircles)
    ang=0:0.01:2*pi;
    hold on
    radius=0.3;
    plot(0.5+radius*cos(ang),0.5+radius*sin(ang),'k-');
    radius=0.2239;
    plot(0.5+radius*cos(ang),0.5+radius*sin(ang),'k-');
    radius=0.4097;
    plot(0.5+radius*cos(ang),0.5+radius*sin(ang),'k-');
    radius=0.4916;
    plot(0.5+radius*cos(ang),0.5+radius*sin(ang),'k-');
    hold off
end


% /*---------------------------------------------------------------------*\
% |                                                                       |
% |                                CLEAN-UP                               |
% |                                                                       |
% \*---------------------------------------------------------------------*/


clear alin blin A B inti shift
clear alabel blabel
