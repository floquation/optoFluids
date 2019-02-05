#! /usr/bin/python
#
import re # Regular-Expressions
import sys, getopt # Command-Line options
import os.path
import subprocess # Execute another python program
import numpy as np # Matrices
#print "THIS SCRIPT IS NOT READY FOR EXECUTION"
#sys.exit(2)
#
scriptDir = os.path.dirname(sys.argv[0])
#
# Command-Line Options
#
pixelCoordsFileName = ""
outputFileName = ""
overwrite = False
#
usageString = "   usage: " + sys.argv[0] + " -i <inputDir with pixelCoords and Intensity files> " \
            + "-o <outputDir for graphs> " \
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

#dataList = []
#with open(pixelCoordsFileName) as pixelCoordsFile:
#    for line in pixelCoordsFile:
#        print line
#        print line.split(' ')
#        inner_list=[float(elt.strip()) for elt in line.split(' ')]
#        dataList.append(inner_list)

floatRE=r"[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?"
dataRegex = "(?m)^\s*("+floatRE+"),\s*("+floatRE+")\s*$" # Matches exactly two floats, comma separated
dataRegex2 = re.compile(dataRegex)
data2D = np.fromregex(pixelCoordsFileName,dataRegex2,dtype='f')
print "data2D = ", data2D







# EOF
