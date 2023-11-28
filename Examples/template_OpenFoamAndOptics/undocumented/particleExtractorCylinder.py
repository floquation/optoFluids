#! /usr/bin/python
#
import re # Regular-Expressions
import sys, getopt # Command-Line options
import os.path, inspect
import subprocess # Execute another python program
from shutil import copyfile, rmtree
import numpy as np
#
##
# This script extracts the particlePositions from openFOAM results within in small volume defined by a cylinder. Used to obtain the particles from the interrogation zones
##
filename = inspect.getframeinfo(inspect.currentframe()).filename
scriptDir = os.path.dirname(os.path.abspath(filename))
#
# Command-Line Options
#
foamCaseDir = ""
outputDir = "./convertFoam2OpticsParticles_out"
cloudName = "particles"
overwrite = False
C = "(0,0)"
R = 0
#
usageString = "   usage: " + sys.argv[0] + " -i <foamCase dir> -C <center of interrogationZone cylinder along X-dir: '(float float)'> -R <radius of interrogation zone cylinder> \n" \
            + "[-o <output dir>] [-c <name of the particle cloud>] [-f] \n" \
	    + " \n" \
            + "     where:\n" \
            + "       -f := force overwrite. WARNING: This will remove any existing directory specified using the -o option, including the default of -o.\n" \
            + "       -o defaults to './convertFoam2OpticsParticles_out\n" \
            + "       -c defaults to 'particles'"
try:
    opts, args = getopt.getopt(sys.argv[1:],"hfi:o:c:C:R:")
except getopt.GetoptError:
    print usageString 
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        print usageString 
        sys.exit(0)
    elif opt == '-i':
        foamCaseDir = arg
    elif opt == '-o':
        outputDir = arg
    elif opt == '-c':
        cloudName = arg
    elif opt == '-C':
	C = arg
    elif opt == '-R':
	R = float(arg)
    elif opt == '-f':
        overwrite = True
    else :
        print usageString 
        sys.exit(2)
#
if foamCaseDir == "" or outputDir == "" or cloudName == "":
    print usageString 
    print "    Note: dir-/filenames cannot be an empty string:"
    print "     foamCaseDir="+foamCaseDir+" outputDir="+outputDir+\
               "cloudName="+cloudName
    sys.exit(2)
#
if R == 0:
    print usageString 
    print "    Note: interrogation zones unspecified: R cannot be 0"
    print "     C=" + str(C) + "	R=" + str(R)
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
print "Output directory '" + outputDir + "' was created."
#
# go go gadget center coords
C = C.strip('(')
C = C.strip(')')
C = C.strip('[')
C = C.strip(']')
C = np.fromstring(C,dtype=float,sep=',')
if np.size(C) != 2 :
    print "\nERROR: Origin must have two space coordinates. "+str(np.size(C))+" were given.\n"
    print usageString
    sys.exit(2)
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
    posFileIn = file( posFileNameIn, "r" )
    posFileOut = file( posFileNameOut, "w" )
    # Detect the starting line in order to remove the header
    intRE=r"[0-9]+"
    myRegex=r"^("+intRE+")$"
    firstLineRE=re.compile(myRegex)
    myRegexPos=r"^(\("+floatRE+"\s"+floatRE+"\s"+floatRE+"\))\s"+intRE+"$"
    posRE=re.compile(myRegexPos)
    myRegexPosSep=r"("+floatRE+")\s("+floatRE+")\s("+floatRE+")"
    sepRE = re.compile(myRegexPosSep)
    pastHeader=False
    particleCount = 0
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
            r2 = posRE.search(line)
            if r2: # "position line": -> remove cellindex
                #print r2.groups()
                #print r2.group(1)
		r3 = sepRE.search(line)
		yCoord = float(r3.group(2))
		zCoord = float(r3.group(3))
		if (((yCoord - C[0])**2 + (zCoord - C[1])**2) < R**2): # then the current line has particle in the given interrogation zone
			particleCount += 1
                	posFileOut.write(r2.group(1)+"\n")
            else: # "other line"
		if ( (not (line[0] == "/")) and (not (line.startswith((" ", "\t","\n")))) and (not (line == "")) ):
			#print "writing line with contents:"
			#print "	" + line
			#print "The test outputs:"
			#print "(not (line == '')) =", (not (line == ""))
			#print "(not (line.startswith((' ', '\t')))) = ", (not (line.startswith((" ", "\t","\n"))))
			#print "(not (line[0] == '/')) = ", (not (line[0] == "/")) 
                	posFileOut.write(line)
    # this part below gets the right number of particles
    posFileOut.close() # first close the file
    posFileOut = file( posFileNameOut, "r+" ) # then open it again in read write
    posFileOut.readline() # skip the first line
    rest = posFileOut.read() # read the remainder
    posFileOut.seek(0,0) # reset the cursor to the first line
    print "		particle count: " + str(particleCount)
    posFileOut.write(str(particleCount)+"\n") # to overwrite the actual number of particles as the new first line
    posFileOut.write(rest) # followed by the rest
    posFileOut.close()
    posFileIn.close() 
    return

#####
# Here the extension by J. Boterman starts
myRegex=r"^("+floatRE+")$"
timeDirRE=re.compile(myRegex)
lijstje = sorted(os.listdir(foamCaseDir))
lijstje = lijstje[:-11] # I manually confirmed there to be 11 non-number objects in 'lijstje'.. maybe make this nicer somehow one day
lijstje = [float(i) for i in lijstje]
lijstje = sorted(lijstje) # now lijstje is just a set of numbers
timeTag = 0
prevTime = 0.0
for itemNum in lijstje :
    item = str(itemNum)
    if itemNum.is_integer():
	    item = '{:d}'.format(int(itemNum))
    r = timeDirRE.search(item)
    if r: # If filename matches the regex
	#diagnostic outputs	
	#print itemNum, prevTime
	#print itemNum - prevTime
	if( itemNum - prevTime > 1000*2.5e-6): #then the timetag should iterate. For this to work, lijstje needs to be sorted by number size!
		timeTag += 1
	# diagnostic output:
        #print timeTag
        time = float(r.group(1)) # Will only match the first group = the time (by the regex definition), the float is a formatting workaround
	#diagnostic output
        print "Now using the directory '" + item + "'. Time="+'{:.7f}'.format(time)+"."
        if os.path.isdir(foamCaseDir + "/" + item): # If the file is a directory
            foamPosFile=foamCaseDir+"/"+item+"/lagrangian/"+cloudName+"/positions"
            newPosFile=outputDir+"/particlePositions_t"+str(timeTag)+"_"+'{:.7f}'.format(time)
            #print "foamPosFile="+foamPosFile
            #print "newPosFile="+newPosFile
            if not os.path.exists(foamPosFile):
                print "WARNING: '"+foamPosFile+" does not exist.\n" \
                + "Please make sure that this path is correct. " \
                + "And if it is, is it correct that the particle positions file does not exist?"
                continue
            # At this point we have acquired the particle positions file
            convertSyntax( foamPosFile, newPosFile )
            # Done! Check the next directory...
	prevTime = itemNum 
# 
#
#
# EOF particleExtractorCylinder
