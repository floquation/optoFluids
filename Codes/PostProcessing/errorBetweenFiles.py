#! /usr/bin/python
#
# errorBetweenFiles.py
#
# Takes the content of two array-like files and outputs to stdout the RMSE (and other error measures) of the difference between the two files.
#  Suitable for float data type.
#
# RMSE = Root Mean Square Error (L2 norm)
# MAE = Mean Absolute Error (L1 norm)
# C = Speckle Contrast = STD(I)/<I>
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
usageString = "Takes the content of two array-like files and outputs to stdout the RMSE (and other error measures) of the difference between the two files.\n" \
            + " Suitable for float data type.\n" \
            + "   usage: " + sys.argv[0] + " <file1> <file2>"
#
#
if np.size(sys.argv) != 3:
    sys.exit(usageString+"\n\nERROR: INVALID NUMBER OF ARGUMENTS. MUST BE EXACTLY 2.")
if sys.argv[1] == "-h" or sys.argv[1] == "--help" or sys.argv[1] == "-help":
    print usageString
    sys.exit(0)
#
FN1 = sys.argv[1] # filename 1
FN2 = sys.argv[2] # filename 2
#
if FN1 == "" or FN2 == "" :
    print usageString 
    print "    Note: dir-/filenames cannot be an empty string:"
    print "     file1="+FN1+" file2="+FN2
    sys.exit(2)
#
# Check for existence of the files
if ( not os.path.exists(FN1) ) :
    sys.exit("\nERROR: Inputfile '" + FN1 + "' does not exist.\n" + \
             "Terminating program.\n" )
if ( not os.path.exists(FN2) ) :
    sys.exit("\nERROR: Inputfile '" + FN2 + "' does not exist.\n" + \
             "Terminating program.\n" )
#
#
###########################
# Algorithm:
##########
###
# Obtain the data and check if its format is identical
#
dataIn1 = np.loadtxt(open(FN1,"rb"),dtype=float)
dataIn2 = np.loadtxt(open(FN2,"rb"),dtype=float)
#
#
###
# Compute several error measures and send them to stdout.
#
####
# Measures that do not require files of the same shape:
##
# Relative speckle contrast
dataMean1 = np.mean(dataIn1)
STD1 = np.sqrt(np.mean(np.square(dataIn1-dataMean1)))
C1 = STD1/dataMean1
dataMean2 = np.mean(dataIn2)
STD2 = np.sqrt(np.mean(np.square(dataIn2-dataMean2)))
C2 = STD2/dataMean2
print "C2/C1=",C2/C1
print "C1/C2=",C1/C2
#
####
# Measures that require files of the same shape:
##
# Errors by taking the difference between the intensity
shape1 = np.shape(dataIn1)
shape2 = np.shape(dataIn2)
if shape1 != shape2 :
    sys.exit( "ERROR: The two files do not have the same shape.\n" \
            + "    Cannot compute any more error measures.\n" \
            + "       Shape1: " + str(shape1) + ". Shape2: " + str(shape2) + ".")
#
dataDiff = dataIn2-dataIn1
dataMAE = np.mean(np.abs(dataDiff)) # Mean |error|
dataRMS = np.sqrt(np.mean(dataDiff*np.conj(dataDiff))) # Root of the mean of the square
np.seterr(divide='ignore',invalid='ignore') # Ignore warnings produces for Inf and NaN results. I want those results.
print "MAE= " + str(dataMAE) # Depends on prefactor
print "RMSE= " + str(dataRMS) # Depends on prefactor
print "mean(Error)= " + str(np.mean(dataDiff)) # Depends on prefactor
print "mean(Error)/RMSE= " + str(np.mean(dataDiff)/dataRMS) # Independent of prefactor, but may be NaN
print "mean(abs(Error))/RMSE= " + str(np.mean(np.abs(dataDiff))/dataRMS) # Independent of prefactor, but may be NaN
print "mean(Data1)/RMSE= " + str(np.mean(dataIn1)/dataRMS) # Independent of prefactor, but may be Inf
print "mean(Data2)/RMSE= " + str(np.mean(dataIn2)/dataRMS) # Independent of prefactor, but may be Inf
print "mean(Data1,Data2)/RMSE= " + str(np.mean(np.concatenate((dataIn1,dataIn2)))/dataRMS) # Independent of prefactor, but may be Inf
print "MAE/mean(Error)= " + str(dataMAE/np.mean(dataDiff)) # Independent of prefactor, but may be NaN
print "RMSE/mean(Error)= " + str(dataRMS/np.mean(dataDiff)) # Independent of prefactor, but may be NaN
print "RMSE/MAE= " + str(dataRMS/dataMAE) # Independent of prefactor, but may be NaN
print "MAE/mean(Data1,Data2)= " + str(dataMAE/np.mean(np.concatenate((dataIn1,dataIn2)))) # Independent of prefactor
print "RMSE/mean(Data1,Data2)= " + str(dataRMS/np.mean(np.concatenate((dataIn1,dataIn2)))) # Independent of prefactor
#
#
#
#
# EOF
