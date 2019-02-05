#! /usr/bin/python
#
# timeIntegrateOptics.py
#
# Computes the intensity sum over all pixels, just like a camera integrates over a finite time period (it cannot measure instantaneously).
#  It is assumed that the time-dimension has been uniformly sampled. I.e., we sum over the files without any reference to the time.
#
# Kevin van As
#  June 23th 2015
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
intensityDirName = ""
outputFileName = ""
overwrite = False
#
usageString = "  Sums all intensity files pixel-by-pixel. Time-integration assumes that time is UNIFORMLY sampled.\n" \
            + "   usage: " + sys.argv[0] + "  -i <intensityDirName> -o <outputFileName> " \
            + "[-f]\n" \
            + "     where:\n" \
            + "       -f := force overwrite. WARNING: This will remove any existing directory specified using the -o option\n" \
            + "       -i := input directory containing all intensity files with uniformly sampled times. NO OTHER FILES ALLOWED.\n" 
try:
    opts, args = getopt.getopt(sys.argv[1:],"hfc:i:o:")
except getopt.GetoptError:
    print usageString 
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        print usageString 
        sys.exit(0)
    elif opt == '-i':
        intensityDirName = arg
    elif opt == '-o':
        outputFileName = arg
    elif opt == '-f':
        overwrite = True
    else :
        print usageString 
        sys.exit(2)
#
if intensityDirName == "" or outputFileName == "" :
    print usageString 
    print "    Note: dir-/filenames cannot be an empty string:"
    print "     intensityDirName="+intensityDirName+" outputFileName="+outputFileName
    sys.exit(2)
#
# Check for existence of the files
if ( not os.path.exists(intensityDirName) ) :
    sys.exit("\nERROR: Inputdir '" + intensityDirName + "' does not exist.\n" + \
             "Terminating program.\n" )
if ( os.path.exists(outputFileName) and not overwrite ) :
    sys.exit("\nERROR: Outputfile '" + outputFileName + "' already exists.\n" + \
             "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n" + \
             "BE WARNED: This will remove the existing file with the same name as the Outputdir!")
#
#
###########################
# Algorithm:
##########
###
# Perform the time integration
#
firstFile=1
for intensityFileName in os.listdir(intensityDirName) :
    print "Now reading file: '"+intensityFileName+"'"
    dataIn = np.loadtxt(open(intensityDirName+"/"+intensityFileName,"rb"),dtype=float)
    if firstFile:
        firstFile=0
        fileShape=np.shape(dataIn)
        dataAccum=dataIn
    else:
        if np.shape(dataIn) == fileShape:
            dataAccum=dataAccum+dataIn
        else:
            print "WARNING. '"+intensityFileName+"' does not have the same shape as the first file read!!!\n" \
                + "         First file has a shape: "+str(fileShape)+", whereas this file has shape: "+str(np.shape(dataIn)) \
                + "\n         File will be IGNORED."
#print dataAccum
#
###
# Write the result to a file
#
#print fileShape
#print np.size(fileShape)
#print fileShape[0]
#print fileShape[1]
if np.size(fileShape)>2 :
    sys.exit("\nERROR: This code does not support matrices that have more than 2 dimensions. Yours has "+str(np.size(fileShape))+".")
if np.size(fileShape)<1 :
    sys.exit("\nERROR: This code does not support matrices that have less than 1 dimension. Yours has "+str(np.size(fileShape))+".")
outputFile = file(outputFileName,"w")
for i1 in range(0, fileShape[0]) :
    line = ""
    if np.size(fileShape)==2:
        for i2 in range(0, fileShape[1]) :
            line = line + str(dataAccum[i1,i2]) + " "
    else : # size 1
        line = line + str(dataAccum[i1]) + " "
    outputFile.write(line[0:-1] + "\n")
outputFile.close()
# EOF
