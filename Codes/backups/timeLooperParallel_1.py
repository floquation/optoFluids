#! /usr/bin/env python3
#
# This script automatically loops over many particlePositions files,
#  assigns the individual files to different processors,
#  and then calls the optics code for each one.
#
# Kevin van As
#	20 06 2015: Original
# Jorne Boterman
#	26 06 2017: Parallelised
# Kevin van As
#   10 09 2018: Got rid of "subprocess" to call other Python modules
#   10 09 2018: Added proc_id message to parallel function
#   12 09 2018: Updated the Mie code with the option to only write pixel coordinates and exit immediately.
#   			  This is now also incooperated in the timeLooper.
#   02 10 2018: particlePositions_tINT_FLOAT is now .*_tINT_FLOAT regex, to allow for shorter names with backward compatibility.
#   02 10 2018: -C now defaults to 1 (=serial run). Use -C 0 to use the available number of system cores instead.
#   02 10 2018: Now also copies (hardcoded) "interpolConfig.dat" to the results directory
#	03 10 2018: Implemented helpers.regex import
#				Added log as subdir of outputDir
#				Removed unused commented variables
#

# Regular imports
import re # Regular-Expressions
import sys, getopt # Command-Line options
import os.path, inspect
import subprocess # Execute shell commands
from shutil import copyfile, rmtree
from multiprocessing import Pool, Value
import multiprocessing
from ctypes import c_bool, c_wchar_p

# OptoFluids imports
from templating.templateSubstitutor import TemplateSubstitutor as ts
import helpers.regex as myRE

#############
# Initialisation
#####
#
filename = inspect.getframeinfo(inspect.currentframe()).filename
scriptDir = os.path.dirname(os.path.abspath(filename))
#
# Command-Line Options, incl. defaults
#
partPosDir = ""
outputDir = ""
opticsCode = scriptDir+"/Mie_MSFF/MieAlgorithmFF_start.out"
#opticsInputTemplateFN=scriptDir+"/inputOptics.template"
opticsInputTemplateFN="./inputOptics.tmplt"
opticsInputInterpolConfig="./interpolConfig.dat"
overwrite = False
logOptics = False
numCores = 1
debug = False
#
usageString = "   usage: " + sys.argv[0] + " -i <particlePositions dir> -o <output dir> " \
            + "[-c <optics code executable>] [-C <number of cores to use>] [-t <opticsInputTemplate file>] [-f] [-l]\n" \
            + "     where:\n" \
            + "       -f := force overwrite. WARNING: This will remove any existing directory specified using the -o option\n" \
            + "       -l := write optics output to a log file in the output directory. Default: do not write.\n" \
            + "       -t defaults to '"+opticsInputTemplateFN+"'\n" \
            + "       -c defaults to '"+opticsCode+"'\n" \
	    + "       -C defaults to '1' (serial run). Use '0' to use all available system cores\n" \
	    + "       -d := debug mode (leaves hidden tmp files)"
try:
    opts, args = getopt.getopt(sys.argv[1:],"hfli:o:t:c:C:d")
except getopt.GetoptError:
    print(usageString)
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        print(usageString)
        sys.exit(0)
    elif opt == '-i':
        partPosDir = arg
    elif opt == '-o':
        outputDir = arg
    elif opt == '-t':
        opticsInputTemplateFN = arg
    elif opt == '-c':
        opticsCode = arg
    elif opt == '-C':
        numCores = int(arg)
    elif opt == '-f':
        overwrite = True
    elif opt == '-l':
        logOptics = True
    elif opt == '-d':
        debug = True
    else :
        print(usageString)
        sys.exit(2)
#
if partPosDir == "" or outputDir == "" or opticsInputTemplateFN == "":
    print(usageString)
    print("    Note: dir-/filenames cannot be an empty string:")
    print("     partPosDir="+partPosDir+" outputDir="+outputDir+\
               "opticsInputTemplateFN="+opticsInputTemplateFN)
    sys.exit(2)
#
# Check for existence of the files
if opticsCode == "" or not os.path.exists(opticsCode) :
    print("\nERROR: opticsCode '"+opticsCode+"' (-c) must exist.")
    print(usageString)
    sys.exit(2)
if ( not os.path.exists(partPosDir) ) :
    sys.exit("\nERROR: Inputdir '" + partPosDir + "' does not exist.\n" + \
             "Terminating program.\n" )
if ( not os.path.exists(opticsInputTemplateFN) ) :
    sys.exit("\nERROR: Inputfile '" + opticsInputTemplateFN + "' does not exist.\n" + \
             "Terminating program.\n" )
if ( os.path.exists(outputDir) and not overwrite ) :
    sys.exit("\nERROR: Outputdir '" + outputDir + "' already exists.\n" + \
             "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n" + \
             "BE WARNED: This will removed the existing Outputdir!")




########
## Define output names
####

# Subdirs:
logDir         = outputDir + "/log"
# Fixed name:
pixelCoordsFN  = outputDir + "/PixelCoords.out"
# Formatters:
intensityFNf   = outputDir + "/Intensity_t{}.out"
logFNf         = logDir    + "/log_t{}.out"
variablesFNf   = logDir    + "/.kva_vars_{}.tmp"
opticsInputFNf = logDir    + "/.kva_opticsinput_{}.tmp"




########
## Prepare for optics call
####


# Iteratively call the optics code using the appropriate input file.
#
# Pseudocode:
# For each ParticlePositions-file, do:
#  Use the template to generate an input-file for the optics code
#   (Remember, I only have to store the PixelCoords exactly once!)
#  Call the optics code
#   (TODO: Dynamic linking or something?? Currently the location of the optics code is hard-coded.)
#  Remove the generated input-file
#   (Its information is contained within the template anyway)
# Copy the template to the output directory, such that the used simulation parameters are logged.
# (Convert ugly fortran output format to a nice format)
#

## Create output directory
if ( os.path.exists(outputDir) and overwrite ) :
	rmtree(outputDir)
os.makedirs(outputDir)
os.makedirs(logDir) # subdir of outputdir
if(debug): print("Output directory '" + outputDir + "' was created.")
# Save the template in the output directory for future reference
copyfile(opticsInputTemplateFN,logDir+"/input.tmplt")
# TODO: Do not hardcode the name "interpolConfig.dat" in Mie_MSFF/src/class_ScatterActuator.f90
copyfile(opticsInputInterpolConfig,logDir+"/interpolConfig.dat")

## Define regex for the particlePositions file
#floatRE=r"[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?"
#intRE=r"[0-9]+"
myRegex = ".*_t" + \
		myRE.group( myRE.group(myRE.intRE)+"_" , False) + "?" + \
		myRE.group(myRE.floatRE)
#myRegex = ".*_t(?:("+myRE.intRE+")_)?("+myRE.floatRE+")"
#myRegex = "particlePositions_t(?:("+intRE+")_)?("+floatRE+")"
#myRegex = "particlePositions_t("+intRE+")_("+floatRE+")"
#myRegex = "particlePositions_t([0-9]+(?:\.[0-9]+)?)\.txt"
partPosFNRE = re.compile(myRegex)

## Create a list of valid particlePositions files
partPosList=os.listdir(partPosDir)
num_total=len(partPosList)
partPosList=myRE.getMatchingItems(partPosList,partPosFNRE)
num_valid=len(partPosList)
print("Number of valid ParticlePositions files found in \"" + \
    partPosDir + "\" (rel. to total number) = " + \
    str(num_valid) + "/" + str(num_total))





########
## Define worker function which calls the optics code
## Will be executed in parallel.
####
progressCounter = Value('i',0)
def processFile(i_file):
	proc_id="["+multiprocessing.current_process().name+"] "
	if(debug): print(proc_id + "Processing file: " + i_file)
	r = partPosFNRE.match(i_file)
	if not r: # Continue iff filename matches the regex
	    return
	index = r.group(1)+"_" if r.group(1) else "" # index is optional
	time = r.group(2) # Will only match the first group = the time (by the regex definition)
	file_id=str(index)+str(time)
	#print("r.groups = ", r.groups())
	#print("index = " + str(index))
	#print("r.group(2) = " + r.group(2))
	variablesFN = variablesFNf.format(file_id)
	opticsInputFN = opticsInputFNf.format(file_id)
	# Create the variables file for templateSubstitutor.py input
	variablesFile = open( variablesFN, "w" )
	variablesFile.write( 
	    #"! Filename of the file holding the particle positions:\n" +
	    "particlePositionsFN=" + partPosDir+"/"+i_file + "\n" +
	    #"\n" +
	    #"! Filename of the intensity-out file: (Use DONOTWRITE to suppress output.)\n" +
	    "intensityFN=" + intensityFNf.format(file_id) + "\n" +
	    #"\n" +
	    #"! Filename of the pixelcoords-out file: (Use DONOTWRITE to suppress output.)\n" +
	    "pixelCoordsFN=DONOTWRITE\n"
	    #"\n" +
	    "onlyWriteCoords=false"
	    )
	variablesFile.close()
	# Call templateSubstitutor.py (note that "overwrite" is 100% safe, since it writes to a newly created directory)
	ts(template=opticsInputTemplateFN,varfile=variablesFN,output=opticsInputFN,overwrite=True).run()
	if(not debug): os.remove(variablesFN) # Remove temporarily file
	# Call the optics code, using the generated optics-input-file:
	print(proc_id + "Calling optics code for ParticlePositions file '" + i_file + "'")
	logFN = logFNf.format(file_id)
	with open(logFN,'w') as logFile:
	    subprocess.call([opticsCode,opticsInputFN], shell=False, stdout=logFile)
	    if not logOptics :
	        os.remove(logFN)
	if(not debug): os.remove(opticsInputFN) # Remove temporarily file
	#
	#if (((num_valid%(progressCounter.value))%5 == 0) and (float(num_valid)/float(progressCounter.value) != float(1))):
	with progressCounter.get_lock():
	    progressCounter.value +=1
	    print(proc_id + str(100*float(progressCounter.value)/float(num_valid))+"% Done")






########
## Function which obtains the camera's pixel coordinates
####
def writePixelCoords():
	print("[Master] Obtaining pixel coordinates.")
	# Define locations
	variablesFN = variablesFNf.format("coords")
	opticsInputFN = opticsInputFNf.format("coords")
	# Create optics input file from template
	variablesFile = open( variablesFN, "w" )
	variablesFile.write( 
    	#"! Filename of the file holding the particle positions:\n" +
		"particlePositionsFN=irrelevant" + "\n" + # When "onlyWriteCoords"=true, this value is ignored by the optics code
		#"\n" +
		#"! Filename of the intensity-out file: (Use DONOTWRITE to suppress output.)\n" +
		"intensityFN=DONOTWRITE" + "\n" +
		#"\n" +
		#"! Filename of the pixelcoords-out file: (Use DONOTWRITE to suppress output.)\n" +
		"pixelCoordsFN=" + pixelCoordsFN + "\n" +
		#"\n" +
		"onlyWriteCoords=true"
		)
	variablesFile.close()
	# Call templateSubstitutor.py (note that "overwrite" is 100% safe, since it writes to a newly created directory)
	ts(template=opticsInputTemplateFN,varfile=variablesFN,output=opticsInputFN,overwrite=True).run()
	# Clean up
	if(not debug): os.remove(variablesFN) # Remove temporarily file
	# Call optics code
	logFN = logFNf.format("coords")
	with open(logFN,'w') as logFile:
		subprocess.call([opticsCode,opticsInputFN], shell=False, stdout=logFile)
		if not logOptics :
			os.remove(logFN)
	if(not debug): os.remove(opticsInputFN) # Remove temporarily file




########
## Start the (parallel) optics call
####

#print("CPU_count = " + str(multiprocessing.cpu_count()))
if(debug): print("")
# Pixel coordinates:
writePixelCoords()
# Intensity files:
if(numCores > 0):
	pool = Pool(processes=numCores)
else:
	pool = Pool()
pool.map(processFile, partPosList)




########
## Postprocessing
####
# TODO KVA Note: I want to have this in a different separate function, not in the optics caller!

# Post-process the pixelcoords (from 3D to 2D),
#  And write them in a nicer, more intuitive format:
#subprocess.call(["python",scriptDir+"/convertPixelCoordsTo2D.py","-i",PixelCoordsPath0, \
# "-o",PixelCoords2DPath] , shell=False)
#subprocess.call(["python",scriptDir+"/convertDataTo2D_timeLooper.py","-i",outputDir, \
# "-o",outputDir+"/2D/"] , shell=False)
#
#
print("Done.")
# EOF
