#! /bin/sh 
# Not sure if this script works.
# It should generate particle positions in a pulsatile flow (exact solution), but I never used it.

##### INPUT #####

matlabCommand="matlab-R2014B"

dPdXmax=1 #Amplitude of the dP/dX forcing: dP/dX(t) = dPdXmax cos(omega0*t)
omega0=1 #Angular frequency of the dP/dX forcing
R=1 #Radius of cylindrical pipe
rho=1 #Mass density
nu=1 #Kinematic viscosity
numParticles=50 #Number of particles
t_min=0 #Starting time of the exact solution
t_max=-1 #Ending time; -1 := one period
t_num=101 #Temporal resolution between t_max and t_min (inclusive)
outputPrefix="./particlePositions_t" #Filename of the particlePositions file (prefix before time is printed)
outputSuffix=".txt" #Same, but now the suffix after the time is printed



##### CODE #####

$matlabCommand -nosplash -nodisplay -nodesktop -r "GenerateParticlePositions($dPdXmax, \
    $omega0, $R, $rho, $nu, $numParticles, $t_min, $t_max, $t_num, '$outputPrefix', '$outputSuffix');quit;"


# TODO: Autoquit matlab on error
# TODO: Write time-dependent visualisation (ask Gyllion?)
