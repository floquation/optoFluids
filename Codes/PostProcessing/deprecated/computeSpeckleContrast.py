#! /usr/bin/python
#
# errorBetweenFiles.py
#
# Takes the content of two array-like files and outputs to stdout the RMSE (and other error measures) of the difference between the two files.
#  Suitable for float data type.
#
# Kevin van As
#  June 24th 2015
#
import sys # Command-Line options
import os.path, inspect
import numpy as np # Matrices
#
filename = inspect.getframeinfo(inspect.currentframe()).filename
scriptDir = os.path.dirname(os.path.abspath(filename))
#
usageString = "Takes an intensity file (in 1D or 2D format), and computes the speckle contrast = STD(I)/<I>.\n" \
            + "   Suitable for float datatype.\n" \
            + "   usage: " + sys.argv[0] + " <intensity file name>"
#
#
if np.size(sys.argv) != 2:
    sys.exit(usageString+"\n\nERROR: INVALID NUMBER OF ARGUMENTS. MUST BE EXACTLY 1.")
if sys.argv[1] == "-h" or sys.argv[1] == "--help" or sys.argv[1] == "-help":
    print usageString
    sys.exit(0)
#
FN = sys.argv[1] # filename
#
if FN == "" : 
    print usageString 
    print "    Note: dir-/filenames cannot be an empty string:"
    sys.exit(2)
#
# Check for existence of the files
if ( not os.path.exists(FN) ) :
    sys.exit("\nERROR: Inputfile '" + FN + "' does not exist.\n" + \
             "Terminating program.\n" )
#
#
###########################
# Algorithm:
##########
###
# Obtain the data and check if its format is identical
#
dataIn = np.loadtxt(open(FN,"rb"),dtype=float)
#print "dataIn = ", dataIn
#
# STD = sqrt(1/N sum_i (x_i - <x>)^2 )
# <x> = 1/N sum_i (x_i) == np.mean(x)
dataMean = np.mean(dataIn)
#print "dataMean=",dataMean
#print "dataIn-dataMean=",dataIn-dataMean
#print "(dataIn-dataMean)^2=",np.square(dataIn-dataMean)
STD = np.sqrt(np.mean(np.square(dataIn-dataMean)))
#print "STD=",STD
C = STD/dataMean
print "C=",C
#
#
# EOF
