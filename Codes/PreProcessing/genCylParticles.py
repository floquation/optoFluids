#! /usr/bin/env python2
# 
# genCylParticles.py
#  Kevin van As
#  11th June 2015
#
# Takes a CYLINDRICAL volume fraction (hematocrit) (V_RBC/V_tot), phi(r)
#  and converts it to a number probability density function and an accumulate probability density function.
#  The latter may be used to insert particles into a cylindrical geometry with the correct distribution.
#
# Rules:
# - The phi data-set cannot have conflicting values. I.e., a different value for phi for the same r.
# - It should include the r=0 point.
# - It should include the r=R_max point (I suppose with a guaranteed zero probability?)
#
# Usage:
#  phi2probdens.py -h 
#  phi2probdens.py -i fig4.dat -o fig4 
#
import sys, getopt # Command-Line options
import os.path, inspect
import subprocess # Execute another python program
from shutil import copyfile, rmtree
import numpy as np # Matrices
import random # random-number generator
import math # mathematics
#
filename = inspect.getframeinfo(inspect.currentframe()).filename
scriptDir = os.path.dirname(os.path.abspath(filename))
#
# Command-Line Options
#
cumProbFileName = ""
N = 1000
R = 1
L = 1
O = "(0,0,0)"
outputFileName= ""
overwrite = False
#
usageString = "   usage: " + sys.argv[0] + " -i <accumProbFunctionFileName for r> -o <output fileName>" \
            + " [-N <numParticles>] [-R <radius of cylinder>] [-L <length of cylinder>]\n" \
            + " [-O <origin of cylinder>] [-f]\n" \
            + "     where:\n" \
            + "       -i := a two-column >=2 row data file which starts at (0,0) and ends at (1,0), which describes the accumulated probability density function\n" \
            + "       -N (int) := number of particles to be generated. Defaults to 1000.\n" \
            + "       -R (float) := maximum radius of cylinder in which the particles are generated. Must be positive. Defaults to 1.\n" \
            + "       -L (float) := length of cylinder in which the particles are generated. Can be negative. Defaults to 1.\n" \
            + "       -O '(float,float,float)' := 3-vector, origin of coordinate system. The base of the cylinder at r=0,z=0. Defaults to (0,0,0).\n" \
            + "       -f := force overwrite. WARNING: This will remove any existing directory specified using the -o option\n"
try:
    opts, args = getopt.getopt(sys.argv[1:],"hfi:o:N:R:L:O:")
except getopt.GetoptError:
    print usageString 
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        print usageString 
        sys.exit(0)
    elif opt == '-i':
        cumProbFileName = arg
    elif opt == '-o':
        outputFileName= arg
    elif opt == '-f':
        overwrite = True
    elif opt == '-N':
        N = int(arg)
    elif opt == '-R':
        R = float(arg)
    elif opt == '-L':
        L = float(arg)
    elif opt == '-O':
        O = arg
    else :
        print usageString 
        sys.exit(2)
#
if R<=0 :
    print usageString
    print "    R must be positive: R>0. R was: ", R
    sys.exit(2)
if cumProbFileName == "" or outputFileName == "" :
    print usageString 
    print "    Note: dir-/filenames cannot be an empty string:"
    print "     cumProbFileName="+cumProbFileName+" outputFileName="+outputFileName
    sys.exit(2)
#
# Check for existence of the files
if not os.path.exists(cumProbFileName) or not os.path.isfile(cumProbFileName) :
    print "\nERROR: inputfile '"+cumProbFileName+"' (-i) must exist and be a file."
    print usageString 
    sys.exit(2)
if ( os.path.exists(outputFileName) and not overwrite ) :
    sys.exit("\nERROR: OutputFile '" + outputFileName + "' (-o) already exists.\n" + \
             "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n" + \
             "BE WARNED: This will remove the existing OutputFile!")
#
if ( os.path.exists(outputFileName) and overwrite ) :
    if os.path.isdir(outputFileName) :
        rmtree(outputFileName)
    else :
        os.remove(outputFileName)
#
# Get the origin into numpy:
O = O.strip('(')
O = O.strip(')')
O = O.strip('[')
O = O.strip(']')
O = np.fromstring(O,dtype=float,sep=',')
if np.size(O) != 3 :
    print "\nERROR: Origin must have three space coordinates. "+str(np.size(O))+" were given.\n"
    print usageString
    sys.exit(2)
#
#####
# Convert phi=V/V to a number probability density function
##
# 1) Load the phi-file, which has two columns: r and phi(r) and convert to [0,1] domain
dt = np.dtype([('r',float),('prob',float)])
cumProb=np.loadtxt(cumProbFileName,dt)
# 2) For each particle, generate a position
with open(outputFileName,'w') as f_handle:
#    f_handle.write("(\n")
    for i in xrange(0,N) :
    # a) Sample random numbers
        rnd = random.random()
        index2 = (cumProb['prob'] > rnd).nonzero()[0][0] # Index just above the requested value
        # Intepolate the radial value
        #  Interpolation coefficient. 0<=f<1. r = r[index2-1]*(1-f)+r[index2]*f:
        f = (rnd-cumProb['prob'][index2-1]) / (cumProb['prob'][index2]-cumProb['prob'][index2-1])
        r = cumProb['r'][index2-1]+f*(cumProb['r'][index2]-cumProb['r'][index2-1])
        r = r*R/cumProb['r'][-1]; # rescale
#        print "maxR=", cumProb['r'][-1];
#        print "rnd=",rnd
#       print "matching_index=",index2
#       print "f=", f
#       print "r=", r
        phi = random.random()*2*math.pi
#       print "phi=",phi
# Original:
        z = random.random()*L
        x = r*math.cos(phi)
        y = r*math.sin(phi)
#        z = r*math.cos(phi)
#        x = random.random()*L
#        y = r*math.sin(phi)
#        print "(x,y,z)_preshift=(",x,",",y,",",z,")"
        # b) Shift origin
        x = x + O[0]
        y = y + O[1]
        z = z + O[2]
#        print "(x,y,z)_postshift=(",x,",",y,",",z,")"
        # c) Write to file
        f_handle.write("("+str(x)+" "+str(y)+" "+str(z)+")\n")
#    f_handle.write(")")
#
#
#print "Done."
# EOF
