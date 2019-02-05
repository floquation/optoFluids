clear
close all
% /*---------------------------------------------------------------------*\
% |                                                                       |
% |                             INPUT                                     |
% |                                                                       |
% \*---------------------------------------------------------------------*/


caseSuffix_int ='_t5e-05'; % used for input, output & particlePositions
caseSuffix_int_additional =''; % used for input and output file directly after 'caseSuffix'
caseSuffix_coords =''; % used for input, output & particlePositions

caseNameGraph = ' (instantaneous)'; % Casename for graph (should start with a spacebar :S)

prefix = '/net/users/kvanas/Simulations/OpenFOAM-2.4.x/run/MEP/cylinder/cylinderA_optics/us_stepsStudy2'; % prefix for dirs
intensityDir = strcat(prefix,'/timeResStudy/selectedIntensityForPlotting'); % directory with the intensity files from optics output
coordsFile = strcat(prefix,'/PixelCoords',caseSuffix_coords,'.out');
intensityFile = strcat(intensityDir,'/Intensity',caseSuffix_int,caseSuffix_int_additional,'.out');
particlePositionsFile = strcat(prefix,'/particlePositions/particlePositions',caseSuffix_int,caseSuffix_int_additional,'.txt');

% caseSuffix_int ='_t'; % used for input, output & particlePositions
% caseSuffix_int_additional ='9.04'; % used for input and output file directly after 'caseSuffix'
% caseSuffix_coords =''; % used for input, output & particlePositions
% caseSuffix_coords_additional =''; % used for input and output file directly after 'caseSuffix'
% 
% caseNameGraph = 'MyCase'; % Casename for graph
% 
% inputdirectory = '/net/users/kvanas/Simulations/OpenFOAM-2.4.x/run/MEP/cylinder/cylinderA_optics/particlePositions_used/'; % particle positions directory
% outputdirectory = '/net/users/kvanas/Simulations/OpenFOAM-2.4.x/run/MEP/cylinder/cylinderA_optics/results/'; % directory with optics output
% coordsFile = strcat(outputdirectory,'PixelCoords',caseSuffix_coords,caseSuffix_coords_additional,'.out');
% intensityFile = strcat(outputdirectory,'Intensity',caseSuffix_int,caseSuffix_int_additional,'.out');
% particlePositionsFile = strcat(inputdirectory,'particlePositions',caseSuffix_int,caseSuffix_int_additional,'.txt');

khat = [ 1, 0, 0 ]; % Just for drawing the IPW

% Boolean switches (0 or 1):
showPixelPoints = 0;
doLogScale = 0;
showAiryCircles = 0;
showIncidentPlane = 0;
do3DScript = 1zz;
do2DScript = 1;

% Interpolation
interpPrecIncr = 2; % E.g., if you have 5 pixels, the interpolation will use interpPrecIncr*5 data points.

% Graphics
pixelMarkerSize = 1; % Blueish pixels
sphereMarkerSize = 10; % Red spheres








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


% data.coords=bsxfun(@minus,data.coords,[0 0.23 0]); % Move camera closer


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
% |                    Call the plotting scripts. DO NOT TOUCH            |
% |                                                                       |
% \*---------------------------------------------------------------------*/

if(do3DScript)
disp 'Now running plotCameraIntensity3D.'
plotCameraIntensity3D
end
if(do2DScript)
disp 'Now running plotCameraIntensity2D.'
plotCameraIntensity2D_old
end





% EOF