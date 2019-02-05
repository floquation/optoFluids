clc
clear
close all
% /*---------------------------------------------------------------------*\
% |                                                                       |
% |                             INPUT                                     |
% |                                                                       |
% \*---------------------------------------------------------------------*/

caseSuffix ='_longDoubleSlit'; % used for input, output & particlePositions
caseSuffix_additional ='_A3_p=5'; % used for input and output file directly after 'caseSuffix'

caseNameGraph = 'Double Slit A3 p=5'; % Casename for graph

inputdirectory = '../../Mie_MSFF/Mie.effectOfScatOrderApr08/';
outputdirectory = '../../Mie_MSFF/Mie.effectOfScatOrderApr08/';
coordsFile = strcat(outputdirectory,'PixelCoords',caseSuffix,caseSuffix_additional,'.out');
intensityFile = strcat(outputdirectory,'Intensity',caseSuffix,caseSuffix_additional,'.out');
particlePositionsFile = strcat(inputdirectory,'particlePositions',caseSuffix);

khat = [ 1, 0, 0 ]; % Just for drawing the IPW

% Boolean switches (0 or 1):
showPixelPoints = 0;
doLogScale = 1;
showAiryCircles = 0;
do3DScript = 1;
do2DScript = 1;

% Interpolation
interpPrecIncr = 2; % E.g., if you have 5 pixels, the interpolation will use interpPrecIncr*5 data points.

% Graphics
pixelMarkerSize = 15; % Blueish pixels
sphereMarkerSize = 25; % Red spheres








% /*---------------------------------------------------------------------*\
% |                                                                       |
% |                      I/O CODE. DO NOT TOUCH.                          |
% |                                                                       |
% \*---------------------------------------------------------------------*/

khat = khat/norm(khat);

% Load data
disp 'Starting to load data.coords.'
data.coords = importdata(coordsFile);
disp 'Starting to load data.int.'
data.int = importdata(intensityFile);

disp 'Starting to load data.spherePos.'
fileID = fopen(particlePositionsFile,'r');
numPoints = fscanf(fileID,'%d',1);
fscanf(fileID,'%s\n',1);
formatSpec = '(%f %f %f)\n';
sizeA = [3 numPoints];
data.spherePos = fscanf(fileID,formatSpec,sizeA)';
fclose(fileID);
clear fileID formatSpec sizeA numPoints




% /*---------------------------------------------------------------------*\
% |                                                                       |
% |                 SOME POSTPROCESSING. DO NOT TOUCH.                    |
% |                                                                       |
% \*---------------------------------------------------------------------*/

%%%%%%
% Determine the 2D camera plane
%%%%%%%%%%%%%%

% Define the origin shift, such that v_0 is the origin of the a,b system in
% x,y,z space.
dO = data.coords(1,:);
% Define the horizontal and diagonal:
v_01 = data.coords(2,:)-dO;
v_0N = data.coords(length(data.coords(:,1)),:)-dO;
% Define a horizontal and vertical which spawn the full camera size:
a = dot(v_0N,v_01)/dot(v_01,v_01)*v_01;
b = v_0N - a; % vertical
% The horizontal is along the r1 direction of the camera.
% The vertical is along a superposition of the r1 and r2 direction, which
% is simply equal to the r2 direction if r1 and r2 are orthogonal.

% Rewrite the 4D data to 3D using this planar convention:
A = zeros(size(data.coords));
A(:,1) = a(1);
A(:,2) = a(2);
A(:,3) = a(3);
B = zeros(size(data.coords));
B(:,1) = b(1);
B(:,2) = b(2);
B(:,3) = b(3);
DO = zeros(size(data.coords));
DO(:,1) = dO(1);
DO(:,2) = dO(2);
DO(:,3) = dO(3);
% r = dot(data.coords,A,2)*a/dot(a,a)+dot(data.coords,B,2)*b/dot(b,b); % Sanity check: x,y,z coordinates again: r==data.coords
data2D.coords = [dot(data.coords-DO,A,2)/dot(a,a), dot(data.coords-DO,B,2)/dot(b,b)]; % Coordinates in the a,b-system.
clear v_01 v_0N dO DO

% Determine the shape of the data points:
linIncrease = (data2D.coords(end,2)-data2D.coords(1,2))/length(data2D.coords(:,2));
% The second coordinate jumps from e.g. 0 to 0.25 to 0.5 to 0.75 to 1 if we have 5 pixels in the a-direction.
% linIncrease can be used to determine whether a jump occurs, taking into account any numerical rounding errors.
Q=find(data2D.coords(:,2)>data2D.coords(1,2)+linIncrease); % Use the structure of the second column to determine the number of different element in the first column.
camSize = zeros(1,2);
camSize(1) = Q(1)-1;
camSize(2) = length(data2D.coords(:,2))/camSize(1);

% Cap the values between 0 and 1 (which they should be, but they may
% differ O(eps) cause of rounding errors, which makes the interpolation
% NaN).
% data2D.coords(data2D.coords<0)=0;
% data2D.coords(data2D.coords>1)=1;
% Similarly, (like in Q), the step must neccessarily be greater than
% linIncrease, so:
data2D.coords(data2D.coords>1-linIncrease)=1;
data2D.coords(data2D.coords<0+linIncrease)=0;

clear Q linIncrease


%%%   DONE   %%%
%%% NOW PLOT %%%


% /*---------------------------------------------------------------------*\
% |                                                                       |
% |                    Call the plotting scripts.                         |
% |                                                                       |
% \*---------------------------------------------------------------------*/

if(do3DScript)
disp 'Now running plotCameraIntensity3D.'
plotCameraIntensity3D
end
if(do2DScript)
disp 'Now running plotCameraIntensity2D.'
plotCameraIntensity2D
end





% EOF