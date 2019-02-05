#! /usr/bin/python
#
import re # Regular-Expressions
import sys, getopt # Command-Line options
import os.path, inspect
import subprocess # Execute another python program
import numpy as np # Matrices
print "@DEPRECATED: convertPixelCoordsTo2D"
#
filename = inspect.getframeinfo(inspect.currentframe()).filename
scriptDir = os.path.dirname(os.path.abspath(filename))
#
# Command-Line Options
#
pixelCoordsFileName = ""
outputFileName = ""
overwrite = False
#
usageString = "   usage: " + sys.argv[0] + " -i <pixelCoordsFileName> -o <outputFileName> " \
            + "[-f]\n" \
            + "     where:\n" \
            + "       -f := force overwrite. WARNING: This will remove any existing directory specified using the -o option\n"
try:
    opts, args = getopt.getopt(sys.argv[1:],"hfi:o:")
except getopt.GetoptError:
    print usageString 
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        print usageString 
        sys.exit(0)
    elif opt == '-i':
        pixelCoordsFileName = arg
    elif opt == '-o':
        outputFileName = arg
    elif opt == '-f':
        overwrite = True
    else :
        print usageString 
        sys.exit(2)
#
if pixelCoordsFileName == "" or outputFileName == "" :
    print usageString 
    print "    Note: dir-/filenames cannot be an empty string:"
    print "     pixelCoordsFileName="+pixelCoordsFileName+" outputFileName="+outputFileName
    sys.exit(2)
#
# Check for existence of the files
if ( not os.path.exists(pixelCoordsFileName) ) :
    sys.exit("\nERROR: Inputfile '" + pixelCoordsFileName + "' does not exist.\n" + \
             "Terminating program.\n" )
if ( os.path.exists(outputFileName) and not overwrite ) :
    sys.exit("\nERROR: Outputfile '" + outputFileName + "' already exists.\n" + \
             "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n" + \
             "BE WARNED: This will remove the existing file with the same name as the Outputfile!")
#
###########################
# Algorithm:
##########
#
# Read the input file
#

floatRE=r"[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?"
dataRegex = "(?m)^\s*("+floatRE+")\s+("+floatRE+")\s+("+floatRE+")\s*$" # Matches exactly three floats
dataRegex2 = re.compile(dataRegex)
data3D = np.fromregex(pixelCoordsFileName,dataRegex2,dtype='f')
#print "data3D = ", data3D

#
# Find the span vectors (a and b)
#

# Define the origin shift, such that d0 is the origin of the a,b-system in xyz-space.
d0 = data3D[0,:]
#print d0
# Define the horizontal and the diagonal
v_01 = data3D[1,:]-d0
#print v_01
#print data3D.shape
v_0N = data3D[data3D.shape[0]-1,:]-d0
#print v_0N
# Define a horizontal and vertical which span the full camera size:
a = np.dot(v_0N,v_01)/np.dot(v_01,v_01)*v_01
b = v_0N-a
#print "a=", a
#print "b=", b
# The horizontal is along the r1 direction of the camera.
# The vertical is along a superposition of the r1 and r2 direction, which
#  is simply equal to the r2 direction if r1 and r2 are orthogonal.
# I.e., the camera needs not neccesarily be aligned with the b-axis!


#
# Project to xyz coordinates (3D) to ab coordinates (2D)
#

data_a = np.dot(data3D-d0,a)/np.dot(a,a)
#print "shape data_a = ",np.shape(data_a)
#print "size data_a = ",np.size(data_a)
#print data_a.reshape(np.size(data_a),1)
data2D = data_a.reshape(np.size(data_a),1)
#print "shape data2D = ",np.shape(data2D)
#data2D = np.append(data2D,data_a.reshape(2500,1),axis=0)
data_b = np.dot(data3D-d0,b)/np.dot(b,b)
#print "shape data_b = ",np.shape(data_b)
#print "size data_b = ",np.size(data_b)
data_b = data_b.reshape(np.size(data_a),1)
#print "data_b = ", data_b
data2D = np.append(data2D,data_b,axis=1)
#print np.dot(data3D-d0,a)/np.dot(a,a)
#print "data2D = ", data2D
#print "shape=",np.shape(data2D)
#print "size=",np.size(data2D)

#
# Identify the size of the camera in #pixels
#

# If there is only 1 dimension, we would have this interpixel distance:
linIncrease = (data2D[-1,1]-data2D[0,1])/np.size(data2D[:,1])
#print "linIncrease = ", linIncrease

# When there is more than 1 dimension, there are sudden jumps in the dataset, which are greater than linIncrease.
# For example, the a-coordinate would jump from 0 to 0.25 to 0.5 to 0.75 to 1,
#  if we have 5 pixels in the a-direction, while
#  linIncrease would be 0.125<0.25 if there are 2 pixels in the b-direction.

npix_a=np.nonzero(data2D[:,1]>data2D[0,1]+linIncrease)[0][0]
npix_b=np.size(data_a)/npix_a
#print "npix = [" + str(npix_a) + ", " + str(npix_b) + "]"

# Cap the values between 0 and 1 (which they should be, but they may differ O(eps),
#  due to rounding errors, which could give interpolation problems (e.g. NaN)).
# data2D[data2D<0]=0;
# data2D[data2D>1]=1;
# Similarly, (likewise when determining npix), the step must neccessarily be greater than or equal to
#  linIncrease, so:

data2D[data2D>1-linIncrease*0.999]=1
data2D[data2D<0+linIncrease*0.999]=0
#print "data2D = ", data2D


#
# Output to file
#

outputFile = file(outputFileName, "w")
outputFile.write(str(npix_a) + ", " + str(npix_b) + "\n" )
for elem in data2D :
    line = ""
    for elemm in elem :
        line = line + str(elemm) + ", "
    outputFile.write(line[0:-2] + "\n")

outputFile.close()


# EOF
