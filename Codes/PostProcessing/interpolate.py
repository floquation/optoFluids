#! /usr/bin/env python2.7
# interpolate.py
# 
#   Takes an intensity file and increases the spatial resolution by interpolating with method='linear'.
# This interpolation method preserves non-negativity.
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
interpPrec = float(2)
showPlot = False
overwrite = False
#
usageString = "   usage: " + sys.argv[0] + " -c <pixelCoordsFN 2D>  -i <intensityFN> -o <outputDir> " \
            + "[-p <interpolation precision>] [-f] [-s] \n" \
            + "     where:\n" \
            + "       -f := force overwrite. WARNING: This will remove any existing directory specified using the -o option\n" \
            + "       -s := show plot \n" \
            + "       -p := (float) Increase the spatial resolution in both directions by this factor (ceiled if rounding errors). Default=2.\n" 
try:
    opts, args = getopt.getopt(sys.argv[1:],"hfc:i:o:p:s")
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
    elif opt == '-p':
        interpPrec = float(arg)
    elif opt == '-f':
        overwrite = True
    elif opt == '-s':
        showPlot = True
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
# From now on, the first index of dataCoords2D refers to the a-coordinate and the second to b-coordinate
# dataCoords2D_a and _b are a meshgrid of the dataCoords2D vector (which is not created).
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
# Interpolate using "griddata"
##
#
Na_i = int(np.ceil(Na*interpPrec))
Nb_i = int(np.ceil(Nb*interpPrec))
lin_a = np.linspace(np.min(dataCoords2D_a),np.max(dataCoords2D_a),Na_i)
lin_b = np.linspace(np.min(dataCoords2D_b),np.max(dataCoords2D_b),Nb_i)
A, B = np.meshgrid(lin_a, lin_b)
dataInt2D_i = griddata(dataCoords,dataInt, (A,B), method='linear')

if showPlot :
    plt.subplot(211)
    plt.pcolor(dataCoords2D_a,dataCoords2D_b,dataInt2D)
    plt.subplot(212)
    plt.pcolor(A,B,dataInt2D_i)
    plt.show()

####
# Output to file
##
#
# Intensity:
outputFile = file(outputDN + "/Intensity.out", "w")
for i_b in xrange(0,Nb_i) :
    for i_a in xrange(0,Na_i) :
        outputFile.write(str(dataInt2D_i[i_b,i_a]) + "\n")
outputFile.close()
#
# Coordinates:
outputFile = file(outputDN + "/PixelCoords2D.out", "w")
outputFile.write(coordsFile_row1)
outputFile.write(coordsFile_row2)
outputFile.write(str(Na_i) + " " + str(Nb_i) + "\n")
for i_b in xrange(0,Nb_i) :
    for i_a in xrange(0,Na_i) :
        outputFile.write(str(lin_a[i_a]) + " " + str(lin_b[i_b]) + "\n")
outputFile.close()
#
#
#
#
#
#
# EOF
