#! /usr/bin/python
#
# timeIntegrateOptics.py
#
# Computes the intensity sum over all pixels, just like a camera integrates over a finite time period (it cannot measure instantaneously).
#  It is required that the time-dimension has been uniformly sampled. I.e., we sum over the files without any reference to the time.
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
intensityDirName = "" # input
outputDir_or_FileName = "" # output, dir or file depends on value of -R
overwrite = False
doResolution = False
#
usageString = "  Sums all intensity files pixel-by-pixel. Time-integration requires that time is UNIFORMLY sampled.\n" \
            + "   usage: " + sys.argv[0] + "  -i <intensityDirName> -o <outputFileName> " \
            + "[-f] [-R]\n" \
            + "     where:\n" \
            + "       -f := force overwrite. WARNING: This will remove any existing directory specified using the -o option\n" \
            + "       -R := compute the time integration using several resolutions, using (t_max-t_min)/m for all possible m as dt\n" \
            + "             This only works if the time is perfectly uniformly sampled!\n" \
            + "             This will output a directory of files, instead of a single file.\n" \
            + "             The filenames are such that '1' means using only tmin and tmax, and the highest value uses all.\n" \
            + "             In other words, the higher the value, the finer the time resolution.\n" \
            + "       -o := If not -R, output fileName. If -R, output dirName.\n" \
            + "       -i := input directory containing all intensity files with uniformly sampled times. NO OTHER FILES ALLOWED.\n" 
try:
    opts, args = getopt.getopt(sys.argv[1:],"hfc:i:o:R")
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
        outputDir_or_FileName = arg
    elif opt == '-f':
        overwrite = True
    elif opt == '-R':
        doResolution = True
    else :
        print usageString 
        sys.exit(2)
#
if doResolution :
    outputDirName  = outputDir_or_FileName
    if outputDirName == "" :
        print usageString 
        print "    Note: dirnames cannot be an empty string:"
        print "     outputDirName="+outputDirName
else :
    outputFileName = outputDir_or_FileName
    if outputFileName == "" :
        print usageString 
        print "    Note: filenames cannot be an empty string:"
        print "     outputFileName="+outputFileName
#
if intensityDirName == "" :
    print usageString 
    print "    Note: dir-/filenames cannot be an empty string:"
    print "     intensityDirName="+intensityDirName
    sys.exit(2)
#
# Check for existence of the files
if ( not os.path.exists(intensityDirName) ) :
    sys.exit("\nERROR: Inputdir '" + intensityDirName + "' does not exist.\n" + \
             "Terminating program.\n" )
#
# Check for existence of the files
if ( os.path.exists(outputDir_or_FileName) and not overwrite ) :
    sys.exit("\nERROR: OutputDir or OutputFile '" + outputDir_or_FileName + "' already exists.\n" + \
             "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n" + \
             "BE WARNED: This will remove the existing file with the same name!!")
#
if ( os.path.exists(outputDir_or_FileName) and overwrite ) :
    if os.path.isfile(outputDir_or_FileName) :
        os.remove(outputDir_or_FileName)
    elif os.path.isdir(outputDir_or_FileName) :
        rmtree(outputDir_or_FileName)
    else :
        sys.exit("\nERROR: outputDir or outputFile already exists and is neither a file nor a directory ???\n")
if doResolution :
    os.makedirs(outputDirName)
    print "Output directory '" + outputDirName + "' was created."
#
###########################
# Algorithm:
##########
floatRE=r"[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?"
myRegex = "Intensity_t("+floatRE+")\.out"
intensityFileNameRE = re.compile(myRegex)
###
# Obtain t_min and t_max to be used for resolution
#
tmin=float('inf')
tmax=-float('inf')
numFiles=0
for intensityFileName in os.listdir(intensityDirName) :
    #print "Now reading file: '"+intensityFileName+"'"
    r = intensityFileNameRE.search(intensityFileName)
    if r: # If filename matches the regex
        time = float(r.group(1)) # Will only match the first group = the time (by the regex definition)
        #print "time=",time
        tmin = min(tmin,time)
        tmax = max(tmax,time)
        numFiles = numFiles+1
    else: #Invalid file detected
        print "WARNING. '"+intensityFileName+"' does have have a correct filename!!!\n" \
            + "        It will be assumed that it is not an intensity file and thus will be IGNORED.\n" \
            + "        Regex used = '" + myRegex + "'"
DT = tmax-tmin
step = DT/(numFiles-1)
#print "DT  =",DT
#print "step=",step
#
###
# See what integer period fits in the number of files to determine what resolutions we can try
# Then, using those integers, perform the time integration by leaving files out ("coarser resolution")
#
# Tm is the period in integer m. If Tm=1, all files will be taken. If Tm=numFiles, only tmin and tmax are taken.
# Then, T=Tm*step are the steps in time to be used.
# So, if some time, t, is such that (t-tmin)/T=integer, then it should be used for the time integration.
#
for m in xrange(1,numFiles) :
    if not doResolution :
        m = numFiles-1
    # See if this m has an integer period
    Tm=float(numFiles-1)/m # period in m, if it is an integer
    if not Tm == float(int(Tm)) : # If is not an integer, then not a suitable value for m.
        continue
    Tm = int(Tm)
    T = Tm*step
    print "Tm = ", Tm
#    print "T  = ", T
    # Perform the time integration using only times that satisfy (t-tmin)/T=integer
    firstFile=1
    for intensityFileName in os.listdir(intensityDirName) :
        r = intensityFileNameRE.search(intensityFileName)
        if r: # If filename matches the regex
            time = float(r.group(1))
            print "Now trying to read file: '"+intensityFileName+"' with t=",time
            # Only use the times that satisfy (t-tmin)/T=integer:
            x=(time-tmin)/T
            xstep=((tmax-tmin)/T)/(numFiles-1)
#            print "(t-tmin)/T=",x
#            print "(t-tmin)=",(time-tmin)
#            print "tmin=",tmin
            #print "DT/T=",DT/T
            #print "xstep=",xstep
            if not x == 0 :
                #print "error=",abs(x-float(int(x)))/xstep
                if abs(x-float(int(x+1e-6)))/xstep > 1e-5 : # approximately an integer, due to rounding errors
		    print time, " is invalid for T=",T,"."
#		    print "abs(x-float(int(x+1e-6)))/xstep=",abs(x-float(int(x+1e-6)))/xstep
#		    print "abs(x-float(int(x+1e-6)))/x=",abs(x-float(int(x+1e-6)))/x
                    continue # Invalid time!
            #print "---> ", time, " use this time!"
 #           print "Now reading file: '"+intensityFileName+"' with t=",time
            dataIn = np.loadtxt(open(intensityDirName+"/"+intensityFileName,"rb"),dtype=float)
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
                    print "WARNING. '"+intensityFileName+"' does not have the same shape as the first file read!!!\n" \
                        + "         First file has a shape: "+str(fileShape)+", whereas this file has shape: "+str(np.shape(dataIn)) \
                        + "\n         The present file will be IGNORED."
    dataAv=dataAccum/numTerms
    print dataAv
    #
    ###
    # Write the result to a file
    #
    if np.size(fileShape)>2 :
        sys.exit("\nERROR: This code does not support matrices that have more than 2 dimensions. Yours has "+str(np.size(fileShape))+".")
    if np.size(fileShape)<1 :
        sys.exit("\nERROR: This code does not support matrices that have less than 1 dimension. Yours has "+str(np.size(fileShape))+".")
    if doResolution :
        outputFileName = outputDirName + "/" + str((numFiles-1)/Tm)
    outputFile = file(outputFileName,"w")
    for i1 in range(0, fileShape[0]) :
        line = ""
        if np.size(fileShape)==2:
            for i2 in range(0, fileShape[1]) :
                line = line + str(dataAv[i1,i2]) + " "
        else : # size 1
            line = line + str(dataAv[i1]) + " "
        outputFile.write(line[0:-1] + "\n")
    outputFile.close()
    if not doResolution : # If we do not compute it for every resolution, we can break the m-loop now.
        break
#
#
#
# EOF
