% Loops over time files, plotting a repeated sequence of images
clear
close all
% /*---------------------------------------------------------------------*\
% |                                                                       |
% |                             INPUT                                     |
% |                                                                       |
% \*---------------------------------------------------------------------*/

caseSuffix_int ='_t'; % used for input, output & particlePositions
caseSuffix_int_additional ='0'; % used for input and output file directly after 'caseSuffix'
caseSuffix_coords =''; % used for input, output & particlePositions

caseNameGraph = ' us\_stepsStudy'; % Casename for graph (should start with a spacebar :S)

prefix = '/net/users/kvanas/Simulations/OpenFOAM-2.4.x/run/MEP/cylinder/cylinderA_optics/us_stepsStudy'; % prefix for dirs
intensityDir = strcat(prefix,'/intensityFiles'); % directory with the intensity files from optics output


% Boolean switches (0 or 1):
showPixelPoints = 1; % Show a dot at the position of the grid point (at which the data is known)
doLogScale = 1; % Plot everything in log, or lin?
do2DScript = 1; % Plot 2D figures

doPixelPlot = 1; % Show the pixel plot (no interpolation)
doInterpPlot = 1; % Show the smoothed/interpolated plot

interpPrecIncr = 2; % Number of interpolation points per grid point
numInterpBits = 1000; % Number of bits on the color bar

% Graphics
pixelMarkerSize = 1; % Blueish pixels





% /*---------------------------------------------------------------------*\
% |                                                                       |
% |                      I/O CODE. DO NOT TOUCH.                          |
% |                                                                       |
% \*---------------------------------------------------------------------*/

coordsFile = strcat(prefix,'/PixelCoords2D',caseSuffix_coords,'.out');
%%%%%
% Load coords
%%%
disp 'Starting to load data.coords.'
fileID = fopen(coordsFile,'r');
aStr = fgetl(fileID);
bStr = fgetl(fileID);
a = textscan(aStr,'%s %s %f %f %f');
b = textscan(bStr,'%s %s %f %f %f');
a = [a{3} a{4} a{5}];
b = [b{3} b{4} b{5}];
camSize = fscanf(fileID,'%d, %d\n',2)';
formatSpec = '%f %f\n';
sizeA = [2 camSize(1)*camSize(2)];
data2D.coords = fscanf(fileID,formatSpec,sizeA)';
fclose(fileID);

%%%%%
% Load intensity
%%%
% intensityFile = strcat(intensityDir,'/Intensity',caseSuffix_int,caseSuffix_int_additional,'.out');
intensityFile = strcat(intensityDir,'/Intensity*.out');

files = dir(intensityFile);
numFiles = length(files);
fileTimes = zeros(numFiles,1);
ii=1;
for file = files'
    fileTime=regexp(file.name,'Intensity_t([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?).out','tokens');
    fileTimes(ii)=str2double(fileTime{1}{1});
    ii=ii+1;
end


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


