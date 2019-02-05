% Plots a single figure based on the 2D data
clear all
% close all % Close old graphs?
% format long % Output more digits to the command window?
% /*---------------------------------------------------------------------*\
% |                                                                       |
% |                             INPUT                                     |
% |                                                                       |
% \*---------------------------------------------------------------------*/

caseSuffix_int =''; % used for input, output & particlePositions
caseSuffix_int_additional =''; % used for input and output file directly after 'caseSuffix'
caseSuffix_coords =''; % used for input, output & particlePositions

caseNameGraph = ' (instantaneous)';%': us\_stepsStudy'; % Casename for graph (should start with a spacebar, and possibly a colon or bar if desired)

prefix = '/net/users/kvanas/Simulations/OpenFOAM-2.4.x/run/MEP/cylinder/cylinderA_optics/us_stepsStudy2/timeResStudy'; % prefix for dirs
coordsFile = strcat(prefix,'/integratedTime2D/PixelCoords2D',caseSuffix_coords,'.out');
% intensityFile = strcat(intensityDir,'/Intensity',caseSuffix_int,caseSuffix_int_additional,'.out');
% intensityFile = strcat(intensityDir,'/100');
% intensityFile = strcat(prefix,'/../intensityFiles/Intensity_t5e-05.out');
% intensityFile = strcat(prefix,'/../results_interpolation/intensityFiles/Intensity_t5e-05.out');
intensityFile = strcat(prefix,'/interpolateFirstStudy/integratedIntensityFiles/GC/100');
% intensityFile = strcat(prefix,'/interpolateSecondStudy/results_interpolation/intensityFiles/1');

coordsFile = strcat(prefix,'/../results_interpolation/PixelCoords2D',caseSuffix_coords,'.out'); %interpolated

%%% SpatialResolutionStudy:
prefix = '/net/users/kvanas/Simulations/OpenFOAM-2.4.x/run/MEP/cylinder/cylinderA_optics/resolutionStudy/view0.10deg'; % prefix for dirs
intensityFile = strcat(prefix,'/results/', ...
    'halfResolution/intensityFiles/Intensity_257x257.out');
coordsFile = strcat(prefix,'/results/halfResolution/pixelCoordsFiles/PixelCoords2D_257x257.out');
%%% End SpatialResolutionStudy

%%% VaryPartSizeStudy:
% caseNameGraph = ' (a=1{\mu}m)';
% prefix = '/net/users/kvanas/Simulations/OpenFOAM-2.4.x/run/MEP/cylinder/cylinderA_optics/varyPartSizeStudy/results/'; % prefix for dirs
% intensityFile = strcat(prefix,'/intensityFiles/Intensity_a20e-06.out');
% coordsFile = strcat(prefix,'/PixelCoords2D.out');

% intensityFile = strcat(prefix,'/results_interpolation/intensityFiles/Intensity_a1e-06.out'); % interpolated
% coordsFile = strcat(prefix,'/results_interpolation/PixelCoords2D.out'); % interpolated

% caseNameGraph = ' (<a>)';
% caseNameGraph = ' (<a>_{weighted})';
% intensityFile = strcat(prefix,'/results_meanData/Intensity_mean.out'); % mean data
% intensityFile = strcat(prefix,'/results_meanData/Intensity_wmean.out'); % wmean data
% coordsFile = strcat(prefix,'/PixelCoords2D.out');
% intensityFile = strcat(prefix,'/results_meanData/Intensity_interp_mean.out'); % interpolated mean data
% intensityFile = strcat(prefix,'/results_meanData/Intensity_interp_wmean.out'); % interpolated wmean data
% coordsFile = strcat(prefix,'/results_interpolation/PixelCoords2D.out');
%%% End VaryPartSizeStudy


%%% OrderOfMultiscatteringStudy
% caseNameGraph = ' (p=1)';
% prefix = '/net/users/kvanas/Simulations/OpenFOAM-2.4.x/run/MEP/cylinder/cylinderA_optics/multiScatStudy/results/'; % prefix for dirs
% intensityFile = strcat(prefix,'/intensityFiles/Intensity_ms1.out');
% coordsFile = strcat(prefix,'/PixelCoords2D.out');

%%% End OrderOfMultiscatteringStudy



% intensityFile = '/net/users/kvanas/Simulations/OpenFOAM-2.4.x/run/MEP/cylinder/cylinderA_optics/resolutionStudy/results/Intensity_257x257.out';
% coordsFile = '/net/users/kvanas/Simulations/OpenFOAM-2.4.x/run/MEP/cylinder/cylinderA_optics/resolutionStudy/results/out2D/PixelCoords2D.out';

% Boolean switches (0 or 1):
showPixelPoints = 0; % Show a dot at the position of the grid point (at which the data is known)
doLogScale = 0; % Plot everything in log, or lin?
do2DScript = 1; % Plot 2D figures

doPixelPlot = 1; % Show the pixel plot (no interpolation)
doInterpPlot = 1; % Show the smoothed/interpolated plot
doGradientPlot = 1; % Show a-averaged intensity, which visualises the gradient. Requires doInterpPlot = 1.
doGradientCorrectedPlot = 1; % Show the interpPlot, but corrected for the gradient. Requires doInterpPlot = 1 or doPixelPlot = 1.

interpPrecIncr = 1.01; % Number of interpolation points per grid point
numInterpBits = 1000; % Number of bits on the color bar

% Graphics
pixelMarkerSize = 1; % Blueish pixels








% /*---------------------------------------------------------------------*\
% |                                                                       |
% |                      I/O CODE. DO NOT TOUCH.                          |
% |                                                                       |
% \*---------------------------------------------------------------------*/

% Load data
disp 'Starting to load data.coords.'
fileID = fopen(coordsFile,'r');
aStr = fgetl(fileID);
bStr = fgetl(fileID);
a = textscan(aStr,'%s %s %f %f %f');
b = textscan(bStr,'%s %s %f %f %f');
a = [a{3} a{4} a{5}];
b = [b{3} b{4} b{5}];
camSize = fscanf(fileID,'%d %d\n',2)';
formatSpec = '%f %f\n';
sizeA = [2 camSize(1)*camSize(2)];
data2D.coords = fscanf(fileID,formatSpec,sizeA)';
fclose(fileID);

disp 'Starting to load data.int.'
data.int = importdata(intensityFile);



%%%   DONE   %%%
%%% NOW PLOT %%%


% /*---------------------------------------------------------------------*\
% |                                                                       |
% |                    Call the plotting scripts. DO NOT TOUCH            |
% |                                                                       |
% \*---------------------------------------------------------------------*/

if(do2DScript)
disp 'Now running plotCameraIntensity2D.'
plotCameraIntensity2D
end





% EOF


