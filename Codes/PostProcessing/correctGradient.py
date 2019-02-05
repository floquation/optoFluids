#! /usr/bin/python
#
# correctGradient.py
# 
# Takes an intensity file and divides it by the mean in one specific direction.
#  This way, the gradient (due to the form of the amplitude scattering matrix), may be removed.
#  This is required to be able to compare the Speckle Contrast.
#
# Kevin van As
#  June 29th 2015
#
import re # Regular-Expressions
import sys, getopt # Command-Line options
import os.path, inspect
import subprocess # Execute another python program
import numpy as np # Matrices
from shutil import rmtree
#
filename = inspect.getframeinfo(inspect.currentframe()).filename
scriptDir = os.path.dirname(os.path.abspath(filename))
#
# Command-Line Options
#
intensityFN = ""
pixelCoordsFN = ""
outputFN = ""
cnstaxis=2
overwrite = False
#
usageString = "   usage: " + sys.argv[0] + " -c <pixelCoordsFN>  -i <intensityFN> -o <intensityOutFN> " \
            + "[-f] [-x 1 or 2]\n" \
            + "     where:\n" \
            + "       -f := force overwrite. WARNING: This will remove any existing directory specified using the -o option\n" \
            + "       -x := In what direction does the gradient exist? Defaults to 2 (which is the b-direction). Valid values: {1,2}\n"
try:
    opts, args = getopt.getopt(sys.argv[1:],"hfc:i:o:x:")
except getopt.GetoptError:
    print usageString 
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        print usageString 
        sys.exit(0)
    elif opt == '-c':
        pixelCoordsFN = arg
    elif opt == '-i':
        intensityFN = arg
    elif opt == '-o':
        outputFN = arg
    elif opt == '-x':
        try:
            cnstaxis = int(arg)
        except ValueError:
            print usageString
            print "\nERROR:  The value specified with '-x' must be in {1,2}: AN INTEGER.\n"
            sys.exit(2)
        if cnstaxis < 1 or cnstaxis > 2 :
            print usageString
            print "\nERROR:  The value specified with '-x' must be in {1,2}.\n"
            sys.exit(2)
    elif opt == '-f':
        overwrite = True
    else :
        print usageString 
        sys.exit(2)
#
if intensityFN == "" or pixelCoordsFN == "" or outputFN == "" :
    print usageString 
    print "    Note: dir-/filenames cannot be an empty string:"
    print "     intensityFileName="+intensityFN+" pixelCoordsFileName="+pixelCoordsFN+" outputFileName="+outputFN
    sys.exit(2)
#
# Check for existence of the files
if ( not os.path.exists(intensityFN) ) :
    sys.exit("\nERROR: Inputfile '" + intensityFN + "' does not exist.\n" + \
             "Terminating program.\n" )
if ( not os.path.exists(pixelCoordsFN) ) :
    sys.exit("\nERROR: Inputfile '" + pixelCoordsFN + "' does not exist.\n" + \
             "Terminating program.\n" )
if ( os.path.exists(outputFN) and not overwrite ) :
    sys.exit("\nERROR: Outputfile '" + outputFN + "' already exists.\n" + \
             "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n" + \
             "BE WARNED: This will remove the existing file with the same name as the Outputfile!")
#
#
###########################
# Algorithm:
##########
####
# Read the input file: PixelCoords
##

floatRE=r"[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?"
#dataRegex = "(?m)^\s*("+floatRE+")\s+("+floatRE+")\s*$" # Matches exactly two floats
#dataRegex2 = re.compile(dataRegex)

coordsFile = file(pixelCoordsFN)
mystr = coordsFile.next() # skip "a=" line
mystr = coordsFile.next() # skip "b=" line
mystr = coordsFile.next() # This is the line we want: "Na Nb"
coordsFile.close()

dataRegex = "^\s*([0-9]+)\s+([0-9]+)\s*$" # Matches exactly two ints, space separated
dataRegex2 = re.compile(dataRegex)
r = dataRegex2.search(mystr)
if r: # If filename matches the regex
    Na = int(r.group(1))
    Nb = int(r.group(2))

#print Na, Nb

####
# Read the input file: Intensity
##

#
dataLin = np.fromfile(intensityFN,dtype=float,count=-1,sep=" ")
#dataLin=np.append(dataLin,np.arange(Na)) # TO DEBUG WITH DIFFERENT LENGTHS
#print dataLin
data2D = np.reshape(dataLin,(Nb,Na))
#data2D = np.reshape(dataLin,(Nb+1,Na)) # TO DEBUG WITH DIFFERENT LENGTHS
data2D = np.transpose(data2D)
# From now on, the first index of data2D refers to the a-coordinate and the second to b-coordinate
#print data2D, np.shape(data2D)
#print data2D[:,-1]
#
####
# Correct the gradient
##
#print "data2D = ", data2D, np.shape(data2D)
data2D_mean = np.mean(data2D,axis=2-cnstaxis)
globalmean = np.mean(data2D_mean)
#print "globalmean = ", globalmean
#print "data2D_mean = ", data2D_mean, np.shape(data2D_mean)

#data2D_GC = np.divide(data2D,data2D_mean)
#print "data2D_GC = ", data2D_GC, np.shape(data2D_GC)
if cnstaxis == 1 :
    data2D_GC = data2D/data2D_mean[:,np.newaxis]*globalmean
else :
    data2D_GC = data2D/data2D_mean[np.newaxis,:]*globalmean
#print "data2D_GC = ", data2D_GC, np.shape(data2D_GC)


#
# Output to file
outputFile = file(outputFN, "w")
for i_b in xrange(0,Nb) :
    for i_a in xrange(0,Na) :
        outputFile.write(str(data2D_GC[i_a,i_b]) + "\n")
outputFile.close()
#print np.shape(data2D)

# EOF
