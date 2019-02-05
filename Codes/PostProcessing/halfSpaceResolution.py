#! /usr/bin/python
#
# halfSpaceResolution.py
# 
#   Takes the intensity and pixelCoords files and halves the resolution (in both the a and the b direction) by throwing away data.
# If the original data is of the form Na x Nb, then the new data will be of the form
#  (Na-1)/2+1 x (Nb-1)/2+1.
# This process will continue recursively, until it is no longer possible to half (Na or Nb is even).
# The resolution is halved by throwing away all odd-numbered rows and columns (with index 0 being the first row/column per definition).
#
# Kevin van As
#  June 29th 2015
#
import re # Regular-Expressions
import sys, getopt # Command-Line options
import os.path, inspect
import subprocess # Execute another python program
import numpy as np # Matrices
from scipy.interpolate import griddata
from shutil import rmtree
import matplotlib.pyplot as plt
#
filename = inspect.getframeinfo(inspect.currentframe()).filename
scriptDir = os.path.dirname(os.path.abspath(filename))
#
# Command-Line Options
#
intensityFN = ""
pixelCoordsFN = ""
outputDN = ""
overwrite = False
#
usageString = "   usage: " + sys.argv[0] + " -c <pixelCoordsFN 2D>  -i <intensityFN> -o <outputDir> " \
            + "[-f] \n" \
            + "     where:\n" \
            + "       -f := force overwrite. WARNING: This will remove any existing directory specified using the -o option\n"
try:
    opts, args = getopt.getopt(sys.argv[1:],"hfc:i:o:")
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
        outputDN = arg
    elif opt == '-f':
        overwrite = True
    else :
        print usageString 
        sys.exit(2)
#
if intensityFN == "" or pixelCoordsFN == "" or outputDN == "" :
    print usageString 
    print "    Note: dir-/filenames cannot be an empty string:"
    print "     intensityFileName="+intensityFN+" pixelCoordsFileName="+pixelCoordsFN+" outputDirName="+outputDN
    sys.exit(2)
#
# Check for existence of the files
if ( not os.path.exists(intensityFN) ) :
    sys.exit("\nERROR: Inputfile '" + intensityFN + "' does not exist.\n" + \
             "Terminating program.\n" )
if ( not os.path.exists(pixelCoordsFN) ) :
    sys.exit("\nERROR: Inputfile '" + pixelCoordsFN + "' does not exist.\n" + \
             "Terminating program.\n" )
if ( os.path.exists(outputDN) and not overwrite ) :
    sys.exit("\nERROR: Outputfile '" + outputDN + "' already exists.\n" + \
             "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n" + \
             "BE WARNED: This will remove the existing file with the same name as the Outputdir!")
#
#
if ( os.path.exists(outputDN) and overwrite ) :
    rmtree(outputDN)
os.makedirs(outputDN)
print "Output directory '" + outputDN + "' was created."
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
coordsFile_row1 = coordsFile.next() # skip "a=" line
coordsFile_row2 = coordsFile.next() # skip "b=" line
coordsFile_row3 = coordsFile.next() # This is the line we want: "Na Nb"
coordsFile.close()
dataRegex = "^\s*([0-9]+)\s+([0-9]+)\s*$" # Matches exactly two ints, space separated
dataRegex2 = re.compile(dataRegex)
r = dataRegex2.search(coordsFile_row3)
if r: # If filename matches the regex
    Na = int(r.group(1))
    Nb = int(r.group(2))
dataCoords = np.loadtxt(pixelCoordsFN, skiprows=3)
dataCoords2D_a = np.reshape(dataCoords[:,0],(Nb,Na))
dataCoords2D_a = np.transpose(dataCoords2D_a)
dataCoords2D_b = np.reshape(dataCoords[:,1],(Nb,Na))
dataCoords2D_b = np.transpose(dataCoords2D_b)
#
####
# Read the input file: Intensity
##
#
dataInt = np.fromfile(intensityFN,dtype=float,count=-1,sep=" ")
dataInt2D = np.reshape(dataInt,(Nb,Na))
dataInt2D = np.transpose(dataInt2D)
# From now on, the first index of dataInt2D refers to the a-coordinate and the second to b-coordinate
#
####
# Half the resolution recursively
##
#
def isEven(i) :
    return i%2 == 0

def writeIntensityFile(dataInt) :
    """
    Takes the intensity file in 2D array format and writes it to an appropriate file.
    """
    Na = np.shape(dataInt)[0]
    Nb = np.shape(dataInt)[1]
    outputFile = file(outputDN + "/Intensity_"+str(Na)+"x"+str(Nb)+".out", "w")
    for i_b in xrange(0,Nb) :
        for i_a in xrange(0,Na) :
            outputFile.write(str(dataInt[i_a,i_b]) + "\n")
    outputFile.close()
    return

def writePixelCoordsFile(dataCoords_a, dataCoords_b) :
    """
    Takes the pixelCoords file ((a,b) in two separate files) and writes it to an appropriate file
    """
    Na = np.shape(dataCoords_a)[0]
    Nb = np.shape(dataCoords_a)[1]
    outputFile = file(outputDN + "/PixelCoords2D_"+str(Na)+"x"+str(Nb)+".out", "w")
    outputFile.write(coordsFile_row1)
    outputFile.write(coordsFile_row2)
    outputFile.write(str(Na) + " " + str(Nb) + "\n")
    for i_b in xrange(0,Nb) :
        for i_a in xrange(0,Na) :
            outputFile.write(str(dataCoords_a[i_a,i_b]) + " " + str(dataCoords_b[i_a,i_b]) + "\n")
    outputFile.close()

    return

rNa = Na
rNb = Nb
dataInt2D_org = dataInt2D
writeIntensityFile(dataInt2D) # Write finest mesh to output directory as well
writePixelCoordsFile(dataCoords2D_a, dataCoords2D_b) # Same.
while not isEven(rNa) and not isEven(rNb) :
    rNa = (rNa-1)/2+1
    rNb = (rNb-1)/2+1
    print "rNa = ", rNa, "; rNb = ", rNb
    dataInt2D = dataInt2D[::2,::2]
    dataCoords2D_a = dataCoords2D_a[::2,::2]
    dataCoords2D_b = dataCoords2D_b[::2,::2]
    writeIntensityFile(dataInt2D)
    writePixelCoordsFile(dataCoords2D_a, dataCoords2D_b)
#
#
#
#
#
#
# EOF
