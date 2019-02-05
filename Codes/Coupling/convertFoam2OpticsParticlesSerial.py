#! /usr/bin/env python3
#
import re # Regular-Expressions
import sys, getopt # Command-Line options
import os.path, inspect
#import subprocess # Execute another program
from shutil import copyfile, rmtree
#
filename = inspect.getframeinfo(inspect.currentframe()).filename
scriptDir = os.path.dirname(os.path.abspath(filename))
#
# Command-Line Options
#
foamCaseDir = ""
outputDir = "./convertFoam2OpticsParticles_out"
cloudName = "particles"
overwrite = False
#
usageString = "   usage: " + sys.argv[0] + " -i <foamCase dir> [-o <output dir>] " \
            + "[-c <name of the particle cloud>] [-f] \n" \
            + "     where:\n" \
            + "       -f := force overwrite. WARNING: This will remove any existing directory specified using the -o option, including the default of -o.\n" \
            + "       -o defaults to '" + str(outputDir) + "'\n" \
            + "       -c defaults to '" + str(cloudName) + "'"
try:
    opts, args = getopt.getopt(sys.argv[1:],"hfi:o:c:")
except getopt.GetoptError:
    print(usageString)
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        print(usageString)
        sys.exit(0)
    elif opt == '-i':
        foamCaseDir = arg
    elif opt == '-o':
        outputDir = arg
    elif opt == '-c':
        cloudName = arg
    elif opt == '-f':
        overwrite = True
    else :
        print(usageString)
        sys.exit(2)
#
if foamCaseDir == "" or outputDir == "" or cloudName == "":
    print(usageString)
    print("    Note: dir-/filenames cannot be an empty string:")
    print("     foamCaseDir="+foamCaseDir+" outputDir="+outputDir+\
               "cloudName="+cloudName)
    sys.exit(2)
#
# Check for existence of the files
if ( not os.path.exists(foamCaseDir) ) :
    sys.exit("\nERROR: Inputdir (foamCase dir) '" + foamCaseDir + "' does not exist.\n" + \
             "Terminating program.\n" )
if ( os.path.exists(outputDir) and not overwrite ) :
    sys.exit("\nERROR: Outputdir '" + outputDir + "' already exists.\n" + \
             "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n" + \
             "BE WARNED: This will removed the existing Outputdir!")
#
if ( os.path.exists(outputDir) and overwrite ) :
    rmtree(outputDir)
os.makedirs(outputDir)
print("Output directory '" + outputDir + "' was created.")
#
##############
# Algorithm
####
#   Loop over all directories. If it is a time directory, read the particle position file and
# convert the data to the format as required by the optics code
#
floatRE=r"[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?"
#####
def convertSyntax( posFileNameIn, posFileNameOut ):
    """
    Converts the data format of an OpenFOAM particlePositions file to the format required by the optics code.
    @IN: posFileNameIn: OpenFoam particlePositions filename
                        This file will be read.
    @IN: posFileNameOut: particlePositions filename with optics formatting
                         This file will be overwritten or created.
    """
    posFileIn = open( posFileNameIn, "r" )
    posFileOut = open( posFileNameOut, "w" )
    # Detect the starting line in order to remove the header
    intRE=r"[0-9]+"
    myRegex=r"^("+intRE+")$"
    firstLineRE=re.compile(myRegex)
    pastHeader=False
    for line in posFileIn :
        r = firstLineRE.search(line)
        if r:
            # The present line is the first line
            pastHeader=True
        if pastHeader:
            # Copy the remainder of the file to the new file. This is automatically the correct formatting.
            # The cellindex behind every position is ignored by the optics code, but we will remove it anyway for matlab convenience.
            # Any additional lines at the bottom are ignored too.
            # The optics code only reads the number of lines as specified by the first integer: numParticles.
            myRegexPos=r"^(\("+floatRE+"\s"+floatRE+"\s"+floatRE+"\))\s"+intRE+"$"
            posRE=re.compile(myRegexPos)
            r2 = posRE.search(line)
            if r2: # "position line": -> remove cellindex
                #print r2.groups()
                #print r2.group(1)
                posFileOut.write(r2.group(1)+"\n")
            else: # "other line"
                posFileOut.write(line)
    posFileOut.close()
    posFileIn.close() 
    return
#####
#
myRegex=r"^("+floatRE+")$"
timeDirRE=re.compile(myRegex)
for item in os.listdir(foamCaseDir) :
    r = timeDirRE.search(item)
    if r: # If filename matches the regex
        time = r.group(1) # Will only match the first group = the time (by the regex definition)
        print("Now using the directory '" + item + "'. Time="+time+".")
        if os.path.isdir(foamCaseDir + "/" + item): # If the file is a directory
            foamPosFile=foamCaseDir+"/"+item+"/lagrangian/"+cloudName+"/positions"
            newPosFile=outputDir+"/pos_t"+time #+".txt"
            #print "foamPosFile="+foamPosFile
            #print "newPosFile="+newPosFile
            if not os.path.exists(foamPosFile):
                print("WARNING: '"+foamPosFile+" does not exist.\n" \
                + "Please make sure that this path is correct. " \
                + "And if it is, is it correct that the particle positions file does not exist?")
                continue
            # At this point we have acquired the particle positions file
            convertSyntax( foamPosFile, newPosFile )
            # Done! Check the next directory...
# 
#
#
# EOF convertFoam2OpticsParticles
