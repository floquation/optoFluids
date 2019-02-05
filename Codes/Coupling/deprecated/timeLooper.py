#! /usr/bin/python
#
import re # Regular-Expressions
import sys, getopt # Command-Line options
import os.path, inspect
import subprocess # Execute another python program
from shutil import copyfile, rmtree
#
filename = inspect.getframeinfo(inspect.currentframe()).filename
scriptDir = os.path.dirname(os.path.abspath(filename))
#
# Command-Line Options
#
partPosDir = ""
outputDir = ""
opticsCode = scriptDir+"/MieAlgorithmFF_start"
opticsInputTemplateFileName=scriptDir+"/inputOptics.template"
overwrite = False
logOptics = False
#
usageString = "   usage: " + sys.argv[0] + " -i <particlePositions dir> -o <output dir> " \
            + "[-c <optics code executable>] [-t <opticsInputTemplate file>] [-f] [-l]\n" \
            + "     where:\n" \
            + "       -f := force overwrite. WARNING: This will remove any existing directory specified using the -o option\n" \
            + "       -l := write optics output to a log file in the output directory. Default: do not write.\n" \
            + "       -t defaults to 'scriptDir/inputOptics.template'\n" \
            + "       -c defaults to 'scriptDir/MieAlgorithmFF_start'"
try:
    opts, args = getopt.getopt(sys.argv[1:],"hfli:o:t:c:")
except getopt.GetoptError:
    print usageString 
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        print usageString 
        sys.exit(0)
    elif opt == '-i':
        partPosDir = arg
    elif opt == '-o':
        outputDir = arg
    elif opt == '-t':
        opticsInputTemplateFileName = arg
    elif opt == '-c':
        opticsCode = arg
    elif opt == '-f':
        overwrite = True
    elif opt == '-l':
        logOptics = True
    else :
        print usageString 
        sys.exit(2)
#
if partPosDir == "" or outputDir == "" or opticsInputTemplateFileName == "":
    print usageString 
    print "    Note: dir-/filenames cannot be an empty string:"
    print "     partPosDir="+partPosDir+" outputDir="+outputDir+\
               "opticsInputTemplateFileName="+opticsInputTemplateFileName
    sys.exit(2)
#
# Check for existence of the files
if opticsCode == "" or not os.path.exists(opticsCode) :
    print "\nERROR: opticsCode '"+opticsCode+"' (-c) must exist."
    print usageString 
    sys.exit(2)
if ( not os.path.exists(partPosDir) ) :
    sys.exit("\nERROR: Inputdir '" + partPosDir + "' does not exist.\n" + \
             "Terminating program.\n" )
if ( not os.path.exists(opticsInputTemplateFileName) ) :
    sys.exit("\nERROR: Inputfile '" + opticsInputTemplateFileName + "' does not exist.\n" + \
             "Terminating program.\n" )
if ( os.path.exists(outputDir) and not overwrite ) :
    sys.exit("\nERROR: Outputdir '" + outputDir + "' already exists.\n" + \
             "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n" + \
             "BE WARNED: This will removed the existing Outputdir!")
#
# Iteratively call the optics code using the appropriate input file.
#
# Pseudocode:
# For each ParticlePositions-file, do:
#  Use the template to generate an input-file for the optics code
#   (Remember, I only have to store the PixelCoords exactly once!)
#  Call the optics code
#   (Dynamic linking or something?? Currently the location of the optics code is hard-coded.)
#  Remove the generated input-file
#   (Its information is contained within the template anyway)
# Copy the template to the output directory, such that the used simulation parameters are logged.
# Convert ugly fortran output format to a nice format
#
if ( os.path.exists(outputDir) and overwrite ) :
    rmtree(outputDir)
os.makedirs(outputDir)
print "Output directory '" + outputDir + "' was created."
# Save the template in the output directory for future reference
copyfile(opticsInputTemplateFileName,outputDir+"/input.template")
#
floatRE=r"[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?"
myRegex = "particlePositions_t("+floatRE+")\.txt"
#myRegex = "particlePositions_t([0-9]+(?:\.[0-9]+)?)\.txt"
partPosFileNameRE = re.compile(myRegex)
#
# First simply count the number of matches,
#  such that the user can anticipate if this gives an unexpected result.
counter=0 # Count number of valid files as a checksum
counterMax=0 # Count number of valid files
for i_file in os.listdir(partPosDir) :
    counterMax+=1
    print "now checking file: " + i_file
    r = partPosFileNameRE.search(i_file)
    if r: # If filename matches the regex
        counter+=1
#        print "groups: " + str(r.groups())
#        print r.group(0) # Will match the entire regex
#        print r.group(1) # Will match only the first group
#        print r.group(2) # Will match only the second group ... etc.
print "Number of valid ParticlePositions files found (rel. to total number) = " + \
  str(counter) + "/" + str(counterMax)
#
# Now start iterating over the files
PixelCoordsPath = outputDir+"/PixelCoords.out" # The same for all times, so only store it once.
PixelCoords2DPath = outputDir+"/PixelCoords2D.out" # Output of a post-processing utility.
PixelCoordsPath0 = PixelCoordsPath # Store the name, to be used for post-processing.
variablesFileName = outputDir + "/.kva_vars_tmpfile"
opticsInputFileName = outputDir +"/.kva_opticsinput_tmpfile"
isFirstIteration = True # In order to only run certain instructions for the very first file/timestep.
for i_file in os.listdir(partPosDir) : 
    r = partPosFileNameRE.search(i_file)
    if r: # If filename matches the regex
        time = r.group(1) # Will only match the first group = the time (by the regex definition)
        # Create the variables file for templateSubstitutor.py input
        variablesFile = file( variablesFileName, "w" )
        variablesFile.write( 
            "! Filename of the file holding the particle positions:\n" +
            "ParticlePositionsFileName="+partPosDir+"/"+i_file+"\n" +
            "\n" +
            "! Filename of the intensity-out file: (Use DONOTWRITE to suppress output.)\n" +
            "IntensityFileName="+outputDir+"/Intensity_t"+time+".out\n" +
            "\n" +
            "! Filename of the pixelcoords-out file: (Use DONOTWRITE to suppress output.)\n" +
            "PixelCoordsFileName=" + PixelCoordsPath)
        variablesFile.close()
        # Call templateSubstitutor.py (note that -f is 100% safe, since it writes to a newly created directory)
        subprocess.call(["python",scriptDir+"/templateSubstitutor.py","-f","-t",opticsInputTemplateFileName, \
         "-v",variablesFileName, \
         "-o",opticsInputFileName] , shell=False)
        #subprocess.call("python templateSubstitutor.py -f -t " + opticsInputTemplateFileName + \
        # " -v " + variablesFileName + \
        # " -o " + opticsInputFileName , shell=True)
        os.remove(variablesFileName) # Remove temporarily file
        # Call the optics code, using the generated optics-input-file:
        print "Calling optics code for ParticlePositions file '" + i_file + "'"
        logFileName = outputDir + "/log_t"+time
        with open(logFileName,'w') as logFile:
            subprocess.call([opticsCode,opticsInputFileName], shell=False, stdout=logFile)
            if not logOptics :
                os.remove(logFileName)
        os.remove(opticsInputFileName) # Remove temporarily file
        #
        if isFirstIteration : # Prepare for the second timestep
            PixelCoordsPath = "DONOTWRITE"
            isFirstIteration = False
# Post-process the pixelcoords (from 3D to 2D),
#  And write them in a nicer, more intuitive format:
subprocess.call(["python",scriptDir+"/../PostProcessing/convertPixelCoordsTo2D.py","-i",PixelCoordsPath0, \
 "-o",PixelCoords2DPath] , shell=False)
subprocess.call(["python",scriptDir+"/../PostProcessing/convertDataTo2D_timeLooper.py","-i",outputDir, \
 "-o",outputDir+"/2D/"] , shell=False)
#
#
print "Done."
# EOF
