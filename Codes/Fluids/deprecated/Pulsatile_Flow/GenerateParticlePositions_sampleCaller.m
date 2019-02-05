% % % Input

% Pressure Forcing: dP/dX = dPdXmax*cos(omega0*t)
dPdXmax = 1; % Maximum value of dP/dX. Amplitude of the cosine.
omega0 = 2.13; % Angular frequency of the forcing

% Pipe properties
R = 2; % Radius of cylindrical pipe, required for alpha
% L = 1; % Length of the pipe, not required.
% Note that amplitude of oscillation = dPdXmax *
% sqrt(A²+B²)/rho/omega_0², where A=A(r,alpha) and B=B(r,alpha).

% Fluid/Flow properties
rho = 1; % Density of the fluid
nu = 3; % Kinematic viscosity of the fluid

% Output
outputPrefix = './particlePositions_t=';
outputSuffix = '.txt';
t_min = 0;
t_max = -1;
t_num = 101;

% Call the script
GenerateParticlePositions(dPdXmax, omega0, R, rho, nu, numParticles, ...
    t_min, t_max, t_num, outputPrefix, outputSuffix)

%EOF