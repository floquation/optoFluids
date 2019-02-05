% /* Plot 2D scattering figures                                          *\
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

if(doPixelPlot)
    %%%%%%
    % Now plot the intensity in a,b-coordinates.
    %%%%%%%% 1): Without any interpolation whatsoever; 2D
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
    if(doLogScale); inti = log10(abs(inti)); end
    pcolor(A,B,inti)
    xlabel(alabel)
    ylabel(blabel)
    % zlabel('intensity')
    % title('intensity profile on the camera, using duplicate data point at boundary')
    if(doLogScale)
        mytitle=strcat('log10(intensity) profile',caseNameGraph);
    else
        mytitle=strcat('intensity profile',caseNameGraph);
    end
    title(mytitle)

%     set(gca, 'XTick', A(:,1)+shift(1), 'XTickLabel', (A(:,1)')+shift(1));
%     set(gca, 'YTick', B(1,:)+shift(2), 'YTickLabel', (B(1,:)')+shift(2));

    hold on
    if(showPixelPoints); plot3(data2D.coords(:,1),data2D.coords(:,2),data.int,'.','MarkerSize',pixelMarkerSize); end % Exact points
    hold off
    colormap(jet(1000))
    colorbar
    shading('flat');
    
    ax = gca;
    ax.XTick = [0 0.2 0.4 0.6 0.8 1];
    ax.YTick = [0 0.2 0.4 0.6 0.8 1];
    
    
    if(doGradientCorrectedPlot)
        figure();
        inti2=bsxfun (@rdivide, inti, mean(inti,1));
        inti2=inti2*mean(mean(inti));
        if(doLogScale); inti2 = log10(abs(inti2)); end
        pcolor(A,B,inti2)
        xlabel(alabel)
        ylabel(blabel)
        if(doLogScale)
            mytitle=strcat('log10(intensity) profile (GC)',caseNameGraph);
        else
            mytitle=strcat('intensity profile (GC)',caseNameGraph);
        end
        title(mytitle)
        colormap(jet(1000))
        colorbar

        hold on
        if(showPixelPoints); plot3(data2D.coords(:,1),data2D.coords(:,2),data.int,'.','MarkerSize',pixelMarkerSize); end % Exact points
        hold off

        shading('flat') % Fixes a graphics issue

%         axis([min(alin) max(alin), min(blin) max(blin)])
%         caxis([min(min(inti2(1:end-1,1:end-1))), max(max(inti2(1:end-1,1:end-1)))+10*eps(max(max(inti2)))])

    end
    
end

if(doInterpPlot)
    %%%%%%
    % Now plot the intensity in a,b-coordinates, but as a 2D figure
    %%%%%%%% 2):  Interpolated; really 2D
    
    alin = linspace(0,1,camSize(1)*interpPrecIncr); % Interpolation a-range
    blin = linspace(0,1,camSize(2)*interpPrecIncr); % Interpolation b-range
    shift = 1./(2*([length(alin) length(blin)]-1)); % = half distance between subsequent points, potentionally different for a and b.
    [A, B] = meshgrid(alin,blin);
    inti = griddata(data2D.coords(:,1),data2D.coords(:,2),data.int,A,B); % Interpolate intensity.
    alin = [alin, 2*alin(end)-alin(end-1)]; % Hack new column in (back)
    blin = [blin, 2*blin(end)-blin(end-1)]; % Hack new column in (back)
    alin = alin-shift(1);
    blin = blin-shift(2);
    inti = [inti; 2*inti(end,:)-inti(end-1,:)]; inti = [inti, 2*inti(:,end)-inti(:,end-1)]; % Hack new row/column in (back)
    inti_bk = inti; % back-up for next plot, still in linear scale
    if(doLogScale); inti = log10(abs(inti)); end
    % "numInterpBits"-bit map:
    fighandle2D = figure();
    pcolor(alin,blin,inti)
    xlabel(alabel)
    ylabel(blabel)
    if(doLogScale)
        mytitle=strcat('log10(intensity) profile',caseNameGraph);
    else
        mytitle=strcat('intensity profile',caseNameGraph);
    end
    title(mytitle)
    colormap(jet(numInterpBits))
    colorbar

    hold on
    if(showPixelPoints); plot3(data2D.coords(:,1),data2D.coords(:,2),data.int,'.','MarkerSize',pixelMarkerSize); end % Exact points
    hold off
    
    shading('interp') % Fixes a graphics issue

    axis([min(alin) max(alin), min(blin) max(blin)])
    caxis([min(min(inti(1:end-1,1:end-1))), max(max(inti(1:end-1,1:end-1)))+10*eps(max(max(inti)))])

    % This can be uncommented to include 0:
    % caxis([0, max(max(inti(1:end-1,1:end-1)))+10*eps(max(max(inti)))])

    
    if(doGradientPlot)
        %%%%%%
        % Plot the <intensity> gradient in the a-direction
        %%%%%%%%
        figure()
        if(doLogScale)
            logmeaninti = log10(abs(mean(inti_bk,2)));
            meanloginti = mean(log10(abs(inti_bk)),2);
            plot(blin,logmeaninti,'k-')
            hold on
            plot(blin,meanloginti,'r-')
            hold off
        else
           plot(blin,mean(inti_bk,2),'k-') 
        end
        if(doLogScale)
            mytitle=strcat('a-averaged Mean Intensity',caseNameGraph);
            legend('log10(<intensity>)','<log10(intensity)>','location','best')
        else
            mytitle=strcat('a-averaged Mean Intensity',caseNameGraph);
        end
        set(gca, 'Xdir', 'reverse')
        xlabel(blabel)
        ylabel('Mean Intensity')
        title(mytitle)
    end
    
    if(doGradientCorrectedPlot)
        figure();
        inti2=bsxfun (@rdivide, inti_bk, mean(inti_bk,2));
        inti2=inti2*mean(mean(inti_bk));
        if(doLogScale); inti2 = log10(abs(inti2)); end
        pcolor(alin,blin,inti2)
        xlabel(alabel)
        ylabel(blabel)
        if(doLogScale)
            mytitle=strcat('log10(intensity) profile, grad corrected',caseNameGraph);
        else
            mytitle=strcat('intensity profile, grad corrected',caseNameGraph);
        end
        title(mytitle)
        colormap(jet(numInterpBits))
        colorbar

        hold on
        if(showPixelPoints); plot3(data2D.coords(:,1),data2D.coords(:,2),data.int,'.','MarkerSize',pixelMarkerSize); end % Exact points
        hold off

        shading('interp') % Fixes a graphics issue

        axis([min(alin) max(alin), min(blin) max(blin)])
        caxis([min(min(inti2(1:end-1,1:end-1))), max(max(inti2(1:end-1,1:end-1)))+10*eps(max(max(inti2)))])

    end
end


% Speckle Contrast
'As measured:'
meandata=mean(mean(data.int))
diffdata=data.int-meandata;
C = sqrt(mean(mean(diffdata.*diffdata)))/meandata

% Speckle Contrast (GC)
'Gradient corrected:'
data.int_GC=reshape(data.int,camSize);
data.int_GC2 = bsxfun (@rdivide, data.int_GC, mean(data.int_GC,1))*mean(mean(data.int_GC));
meandata=mean(mean(data.int_GC2)); % same as previous data
diffdata=data.int_GC2-meandata;
C = sqrt(mean(mean(diffdata.*diffdata)))/meandata

% Speckle Contrast (interpolated)
alin = linspace(0,1,camSize(1)*interpPrecIncr); % Interpolation a-range
blin = linspace(0,1,camSize(2)*interpPrecIncr); % Interpolation b-range
shift = 1./(2*([length(alin) length(blin)]-1)); % = half distance between subsequent points, potentionally different for a and b.
[A, B] = meshgrid(alin,blin);
inti = griddata(data2D.coords(:,1),data2D.coords(:,2),data.int,A,B); % Interpolate intensity.
'As measured (interpolated):'
meandata=mean(mean(inti));
diffdata=inti-meandata;
C = sqrt(mean(mean(diffdata.*diffdata)))/meandata

% Speckle Contrast (interpolated) (GC)
'Gradient corrected (interpolated):'
inti2=bsxfun (@rdivide, inti, mean(inti,2));
inti2=inti2*mean(mean(inti));
meandata=mean(mean(inti2));
diffdata=inti2-meandata;
C = sqrt(mean(mean(diffdata.*diffdata)))/meandata