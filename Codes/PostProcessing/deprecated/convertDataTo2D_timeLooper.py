#! /usr/bin/python
#
# convertDataTo2D_timeLooper.py
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
inputDirName = ""
outputDirName = ""
overwrite = False
#
usageString = "This script automatically loops over all intensity files in the given directory (-i) and then writes them to a different format in the output directory (-o)\n" \
            + "Filename for coordinates: 'PixelCoords.out'. Filename for intensity: 'Intensity_tFLOAT.out'\n" \
            + "   usage: " + sys.argv[0] + " -i <intensity and pixelCoords dirName> -o <outputDir for 2D data> " \
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
        inputDirName = arg
    elif opt == '-o':
        outputDirName = arg
    elif opt == '-f':
        overwrite = True
    else :
        print usageString 
        sys.exit(2)
#
if inputDirName == "" or outputDirName == "" :
    print usageString 
    print "    Note: dir-/filenames cannot be an empty string:"
    print "     inputDirName="+inputDirName+" outputDirName="+outputDirName
    sys.exit(2)
#
# Check for existence of the files
if ( not os.path.exists(inputDirName) ) :
    sys.exit("\nERROR: Inputdir '" + inputDirName + "' does not exist.\n" + \
             "Terminating program.\n" )
if ( os.path.exists(outputDirName) and not overwrite ) :
    sys.exit("\nERROR: Outputdir '" + outputDirName + "' already exists.\n" + \
             "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n" + \
             "BE WARNED: This will remove the existing file with the same name as the Outputdir!")
#
#
if ( os.path.exists(outputDirName) and overwrite ) :
    rmtree(outputDirName)
os.makedirs(outputDirName)
print "Output directory '" + outputDirName + "' was created."
#
###########################
# Algorithm:
##########
####
# Read the input file: PixelCoords
##
pixelCoordsFileName = inputDirName+"/PixelCoords.out"
pixelCoordsFileName_new = outputDirName+"/PixelCoords.out"
pixelCoordsFileName2D_x = outputDirName+"/PixelCoords2D_x.out"
pixelCoordsFileName2D_y = outputDirName+"/PixelCoords2D_y.out"

if ( not os.path.exists(pixelCoordsFileName) ) :
    sys.exit("\nERROR: Inputfile for the PixelCoords '" + pixelCoordsFileName + "' does not exist.\n" + \
             "Terminating program.\n" )

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
#  The camera can have any shape.
#  The horizontal is defined as the vector from the zeroth to the first pixel.
#  The vertical is defined as the vector orthogonal in the plane of the vector from 0 to 1 and 0 to the last pixel.
#  If the camera is not 2D, no error is raised. The third dimension is simply lost by projection.


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
#
data2D[data2D>1-linIncrease*0.999]=1
data2D[data2D<0+linIncrease*0.999]=0
#
# This is how to reshape it, such that x increases with column number and y increases with row number:
#  To flip these, use: data2Dx=np.transpose(data2Dx) and data2Dy=np.transpose(data2Dy).
#print "data2D[:,0] = ", data2D[:,0]
#print "data2D[:,1] = ", data2D[:,1]
data2Dx = np.reshape(data2D[:,0],(npix_b,npix_a))
data2Dx = np.transpose(data2Dx)
data2Dy = np.reshape(data2D[:,1],(npix_b,npix_a))
data2Dy = np.transpose(data2Dy)
#print "x = ", data2Dx
#print "y = ", data2Dy
#
#
# Output to file
#
outputFile = file(pixelCoordsFileName_new, "w")
outputFile.write("a= "+str(a/np.linalg.norm(a)) + "\n" )
outputFile.write("b= "+str(b/np.linalg.norm(b)) + "\n" )
outputFile.write(str(npix_a) + " " + str(npix_b) + "\n" )
for elem in data2D :
    line = ""
    for elemm in elem :
        line = line + str(elemm) + " "
    outputFile.write(line[0:-1] + "\n")
outputFile.close()
#
outputFile_x = file(pixelCoordsFileName2D_x, "w")
outputFile_y = file(pixelCoordsFileName2D_y, "w")
#outputFile_x.write(str(npix_a) + ", " + str(npix_b) + "\n" )
#outputFile_y.write(str(npix_a) + ", " + str(npix_b) + "\n" )
for i_x in range(0, npix_a) : # x goes into different rows
#(note: this is row-column convention, not an x-y-axis convention)
    line_x = ""
    line_y = ""
    for i_y in range(0, npix_b) : # y goes into different columns
        line_x = line_x + str(data2Dx[i_x,i_y]) + " "
        line_y = line_y + str(data2Dy[i_x,i_y]) + " "
    outputFile_x.write(line_x[0:-1] + "\n")
    outputFile_y.write(line_y[0:-1] + "\n")
outputFile_x.close()
outputFile_y.close()
#print np.shape(data2Dx)
#
#
####
# Read the input files: Intensity_txx.xxx.out
##
#intensityFileName=outputDir+"/Intensity_t"+time+".out"
#
floatRE=r"[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?"
intRE=r"[0-9]+"
myRegex = "Intensity_t(?:("+intRE+")_)?("+floatRE+")"
#myRegex = "Intensity_t("+floatRE+")\.out"
intensityFileNameRE = re.compile(myRegex)
#
# First simply count the number of matches,
#  such that the user can anticipate if this gives an unexpected result.
counter=0 # Count number of valid files as a checksum
counterMax=0 # Count number of files
for i_file in os.listdir(inputDirName) :
    counterMax+=1
#    print "now checking file: " + i_file
    r = intensityFileNameRE.search(i_file)
    if r: # If filename matches the regex
        counter+=1
#        print "groups: " + str(r.groups())
#        print r.group(0) # Will match the entire regex
#        print r.group(1) # Will match only the first group
#        print r.group(2) # Will match only the second group ... etc.
print "Number of valid Intensity.out files found (rel. to total number) = " + \
  str(counter) + "/" + str(counterMax)
#
# Now start iterating over the files to convert the vector data to a 2D array of size (npix_a, npix_b)
for i_file in os.listdir(inputDirName) : 
    r = intensityFileNameRE.search(i_file)
    if r: # If filename matches the regex
        index = r.group(1) # Will only match the first group = the time (by the regex definition)
        time = r.group(2) # Will only match the first group = the time (by the regex definition)
#        dataRegex = "(?m)^\s*("+floatRE+")\s*$" # Matches exactly one float
#        dataRegex2 = re.compile(dataRegex)
#        with open(inputDirName+"/"+i_file,'r') as myfile:
#            for i_line in myfile :
#                print [i_line]
#                r2 = dataRegex2.search(i_line)
#                if r2:
#                    print "groups: " + str(r2.groups())
#                    print r2.group(0) # Will match the entire regex
#                    print r2.group(1) # Will match only the first group
#                    print r2.group(2) # Will match only the first group
#        print inputDirName+"/"+i_file
#        dataLin = np.fromregex(inputDirName+"/"+i_file,dataRegex2,dtype='f')
        dataLin = np.fromfile(inputDirName+"/"+i_file,dtype=float,count=-1,sep=" ")
        #print dataLin
        data2D = np.reshape(dataLin,(npix_b,npix_a))
        data2D = np.transpose(data2D)
        # From now on, the first index of data2D refers to the a-coordinate and the second to b-coordinate
#        print data2D
        #
        #
        # Output to file
        #
        outputFile = file(outputDirName+"/Intensity2D_t"+time+".out", "w")
        for i_x in range(0, npix_a) : # x goes into different rows
        #(note: this is row-column convention, not an x-y-axis convention)
            line = ""
            for i_y in range(0, npix_b) : # y goes into different columns
                line = line + str(data2D[i_x,i_y]) + " "
            outputFile.write(line[0:-1] + "\n")
        outputFile.close()
#        print np.shape(data2D)


# EOF
