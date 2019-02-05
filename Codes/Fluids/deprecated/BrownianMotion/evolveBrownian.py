#! /usr/bin/python
#
# evolveBrownian.py
#
#
# Takes a particlePositions file and evolves it using the given dt and T, then writes it to a new file in a new directory.
#  3D space is assumed.
#
#
# Kevin van As
#  June 26th 2015
#
import re # Regular-Expressions
import sys, getopt # Command-Line options
import os.path, inspect
import subprocess # Execute another python program
import numpy as np # Matrices
import random # Random numbers
import math # sqrt, math.sin, math.cos, pi, ...
from shutil import copyfile, rmtree
#
######
## Unmodifiable Defaults
###
filename = inspect.getframeinfo(inspect.currentframe()).filename
scriptDir = os.path.dirname(os.path.abspath(filename))
#
floatRE=r"[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?"
#
posFNprefix = "particlePositions_t"
posFNsuffix = ".txt"
#
# Command-Line Options
#
inputFN = ""
outputDir = "./evolveBrownian_out"
endTime = 0
N = 0
#D #undefined. user must specify.
overwrite = False
#
usageString = "Evolves the given particlePositions file as a function of time umath.sing Brownian Motion.\n" \
            + " The result is a directory containing the files, with the inputfile being t=0 per definition.\n" \
            + "   usage: " + sys.argv[0] + " -i <particlePositionsFileName> [-o <output dir>] " \
            + "-T <end time> -N <number of time steps> -D <diffusion coefficient> [-f] \n" \
            + "     where:\n" \
            + "       -f := force overwrite. WARNING: This will remove any existing directory specified umath.sing the -o option, including the default of -o.\n" \
            + "       -o defaults to '"+outputDir+"'\n" \
            + "       -i := positions file in the OpticsCode file format\n" \
            + "       -T := (float)   end time of the simulation in [s], relative to the starting time. I.e., 0 = do nothing.\n" \
            + "       -N := (integer) number of time steps. You will have (N+1) files incl. the file specified umath.sing -i. I.e., 0 = do nothing.\n" \
            + "       -D := (float)   molecular diffusivity in [m^2/s]."
# Parse options:
try:
    opts, args = getopt.getopt(sys.argv[1:],"hfi:o:N:T:D:")
except getopt.GetoptError:
    print usageString 
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        print usageString 
        sys.exit(0)
    elif opt == '-i':
        inputFN = arg
    elif opt == '-o':
        outputDir = arg
    elif opt == '-N':
        N = int(arg)
    elif opt == '-T':
        endTime = float(arg)
    elif opt == '-D':
        D = float(arg)
    elif opt == '-f':
        overwrite = True
    else :
        print usageString 
        sys.exit(2)
#
if inputFN == "" or outputDir == "" :
    print usageString 
    print "    Note: dir-/filenames cannot be an empty string:"
    print "     inputfile="+inputFN+" outputDir="+outputDir
    sys.exit(2)
if N <= 0 or endTime <= float(0) :
    print usageString
    print "\n-->N and endTime must be >0."
    sys.exit(2)
try: # Test whether D is defined
    D
except NameError:
    print usageString
    print "\n--> D (diffusivity) was not defined."
    sys.exit(2)
#
# Check for existence of the files
if ( not os.path.exists(inputFN) ) :
    sys.exit("\nERROR: Inputfile '" + inputFN + "' does not exist.\n" + \
             "Terminating program.\n" )
if ( os.path.exists(outputDir) and not overwrite ) :
    sys.exit("\nERROR: Outputdir '" + outputDir + "' already exists.\n" + \
             "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n" + \
             "BE WARNED: This will removed the existing Outputdir!")
#
if ( os.path.exists(outputDir) and overwrite ) :
    rmtree(outputDir)
os.makedirs(outputDir)
print "Output directory '" + outputDir + "' was created."
#
##############
# Algorithm
####
#   
dt = endTime/N # timestep
#####
def doBrownian( dt, pos ):
    """
    Evolves the given positions, pos, over a time dt.
    """
    #print "doBrownian called with: ", dt, pos 
    randn_mu = 0 # random walker "mean" for normal distribution
    randn_sigma = np.sqrt(2*3*D*dt) # random walker "std" for normal distribution

    randt = random.uniform(0,math.pi) # random theta
    randp = random.uniform(0,2*math.pi) # random phi
    randr = random.normalvariate(randn_mu,randn_sigma) # random radius
    randx = randr*math.cos(randp)*math.sin(randt) # random x
    randy = randr*math.sin(randp)*math.sin(randt) # random y
    randz = randr*math.cos(randt) # random z
    
    posNew = pos + [randx, randy, randz]
    #print "doBrownian result pos : ", posNew
    return posNew
#
def readNextPos( posFile ):
    myRegexPos=r"^\(("+floatRE+"\s"+floatRE+"\s"+floatRE+")\)$"
    posRE=re.compile(myRegexPos)
    findingPos = 1
    while findingPos :
        line = posFile.next()
        r2 = posRE.search(line)
        if r2: # "position line": -> remove cellindex
            #print r2.group(1)
            pos = r2.group(1)
            findingPos = 0
        #else: # "other line"
        #    print "other line", line
    return np.fromstring(pos, sep=' ', dtype=float)
#
#
#
######
## Read past the header of the positions file, then use the readNextPos function to do the rest.
###
posFileIn = file( inputFN, "r" )
pastHeader=False
intRE=r"[0-9]+"
myRegex=r"^("+intRE+")$"
firstLineRE=re.compile(myRegex)
for line in posFileIn :
    r = firstLineRE.search(line)
    if r:
        # The present line is the first line
        numPos = int(r.group(1))
        pastHeader=True
    if pastHeader:
        break
#
#print "numPos = ", numPos
pos_old = []
for i in xrange(0,numPos) :
    pos_old = np.append(pos_old,readNextPos(posFileIn))
#print "pos_old = ", pos_old
#print "size = ", np.size(pos_old)
pos_old = np.reshape(pos_old,(numPos,3)) # Assume 3D space
#print "pos_old reshaped = ", pos_old
posFileIn.close()
#
pos_oldest = pos_old # Only required for the validation section below.
######
## Evolve Brownian
###
for i_t in xrange(1,N+1) : # Evolve time until endTime
    print str(i_t)+"/"+str(N)+" --> t=", i_t*dt
    # Compute the new positions via Brownian motion: 3D random walk
    pos_new = []
    for i in xrange(0,numPos) : # Iterate over particles
        pos_new = np.append(pos_new,doBrownian(dt,pos_old[i,:]))
    pos_new = np.reshape(pos_new,(numPos,3)) # Assume 3D space
    #print "pos_old shape = ", np.shape(pos_old)
    #
    # Write the result to a file for the current timestep (could be combined with the above loop, but this reads more nicely, and it is fast anyway):
    outF = file( outputDir+"/"+posFNprefix+str(i_t*dt)+posFNsuffix, "w" )
    outF.write(str(numPos)+"\n")
    outF.write("(\n")
    for i in xrange(0,numPos) : # Iterate over particles
        line = ""
        for j in xrange(0,3) : # Iterate over coordinates, assume 3D
            line = line + str(pos_new[i,j]) + " "
        outF.write("(" + line[:-1] + ")\n")
    outF.write(")\n")
    outF.close()
    # Prepare for next timestep: 
    pos_old = pos_new # continue recursively
#
######
## Gather some statistics:
###
#print "pos_new shape = ", np.shape(pos_new)
#print "pos_oldest_shape = ", np.shape(pos_oldest)
Dvec = np.sum(np.square(pos_new-pos_oldest),1)/(2*endTime*3)
#print "shape(Dvec) = ", np.shape(Dvec)
D = np.mean(Dvec)
#print "D=", D
print "<x^2>=", D*(2*endTime*3)
print "sqrt(<x^2>)=", math.sqrt(D*(2*endTime*3))
#
######
##
###
#
# EOF
