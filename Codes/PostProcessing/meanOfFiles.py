#! /usr/bin/python
#
# meanOfFiles.py
#
# Takes a directory of data files, which must have the same 1D vector or 2D array format, and takes an element-wise mean of those files.
#
# Kevin van As
#  June 30th 2015
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
intensityDN = "" # input
outputFN = "" # output, dir or file depends on value of -R
overwrite = False
doResolution = False
#
usageString = \
              "  Takes a directory of data files, which must have the same 1D vector or 2D array format, and takes an element-wise mean of those files.\n" \
            + "   usage: " + sys.argv[0] + "  -i <intensityDN> -o <outputFN> " \
            + "[-f]\n" \
            + "     where:\n" \
            + "       -f := force overwrite. WARNING: This will remove any existing directory specified using the -o option\n" \
            + "       -o := averaged data file name\n" \
            + "       -i := input directory containing all data files with the same shape & format. NO OTHER FILES ALLOWED.\n" 
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
        intensityDN = arg
    elif opt == '-o':
        outputFN = arg
    elif opt == '-f':
        overwrite = True
    else :
        print usageString 
        sys.exit(2)
#
if outputFN == "" :
    print usageString 
    print "    Note: filenames cannot be an empty string:"
    print "     outputFN="+outputFN
    sys.exit(2)
#
if intensityDN == "" :
    print usageString 
    print "    Note: dir-/filenames cannot be an empty string:"
    print "     intensityDN="+intensityDN
    sys.exit(2)
#
# Check for existence of the files
if ( not os.path.exists(intensityDN) ) :
    sys.exit("\nERROR: Inputdir '" + intensityDN + "' does not exist.\n" + \
             "Terminating program.\n" )
#
# Check for existence of the files
if ( os.path.exists(outputFN) and not overwrite ) :
    sys.exit("\nERROR: OutputFile '" + outputFN + "' already exists.\n" + \
             "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n" + \
             "BE WARNED: This will remove the existing file with the same name!!")
#
#
###########################
# Algorithm:
##########
floatRE=r"[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?"

#numFiles = np.size(os.listdir(intensityDN))

# Read all files and sum/accumulate the data:
firstFile=1
for intensityFN in os.listdir(intensityDN) :
    print "Now reading file: '"+intensityFN+"'"
    if not os.path.isfile(intensityDN+"/"+intensityFN) :
        print "--> Is a directory. Skipping it."
        continue
    dataIn = np.loadtxt(open(intensityDN+"/"+intensityFN,"rb"),dtype=float)
    if firstFile:
        firstFile=0
        fileShape=np.shape(dataIn)
        dataAccum=dataIn
        numTerms=1
    else:
        if np.shape(dataIn) == fileShape:
            dataAccum=dataAccum+dataIn
            numTerms=numTerms+1
        else:
            print "WARNING. '"+intensityFN+"' does not have the same shape as the first file read!!!\n" \
                + "         First file has a shape: "+str(fileShape)+", whereas this file has shape: "+str(np.shape(dataIn)) \
                + "\n         The present file will be IGNORED."

# Convert the sum to the mean/average:
dataAv=dataAccum/numTerms
#print dataAv


#
# Write the result to a file:
if np.size(fileShape)>2 :
    sys.exit("\nERROR: This code does not support matrices that have more than 2 dimensions. Yours has "+str(np.size(fileShape))+".")
if np.size(fileShape)<1 :
    sys.exit("\nERROR: This code does not support matrices that have less than 1 dimension. Yours has "+str(np.size(fileShape))+".")
outputFile = file(outputFN,"w")
for i1 in range(0, fileShape[0]) :
    line = ""
    if np.size(fileShape)==2:
        for i2 in range(0, fileShape[1]) :
            line = line + str(dataAv[i1,i2]) + " "
    else : # size 1
        line = line + str(dataAv[i1]) + " "
    outputFile.write(line[0:-1] + "\n")
outputFile.close()
#
#
#
# EOF
