#! /usr/bin/env python3
#
# timeIntegrateOptics_timeLooper.py
#
# Calls timeIntegrateOptics.py to average over the microsteps for every major step found in the optics results directory (-i).
# Automatically chooses the "2D" directory if present, otherwise "1D" if present, otherwise uses the root directory.
#
# Kevin van As
#	17 10 2018: Original
#	18 02 2019: Added progress bar with tdqm
#			

# Misc imports
import re # Regular-Expressions
import sys, getopt # Command-Line options
import os.path
from shutil import rmtree

# Progress bar
from tqdm import tqdm

# Import from optoFluids:
import helpers.regex as myRE
import helpers.nameConventions as names
from timeIntegrateOptics import timeIntegrateOptics as integrateOneDir





########
## Check Validity of Input Parameters
####
def checkArgumentValidity(inputDN, outputDN, overwrite=False):
	## None checks:
	if ( inputDN == None or inputDN == "" ):
		print(usageString )
		print("    ERROR: input directory cannot be an empty string!")
		sys.exit(2)
	## Existence checks:
	# Check for existence of the files
	if ( not os.path.exists(inputDN) ) :
		sys.exit("\nERROR: Inputdir '" + inputDN + "' does not exist.\n" + \
				 "Terminating program.\n" )
	# Check for existence of the files
	if ( os.path.exists(outputDN) and not os.path.samefile(inputDN, outputDN) and not overwrite ) :
		sys.exit("\nERROR: Output location '" + outputDN + "' already exists.\n" + \
				 "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n" + \
				 "BE WARNED: This will remove the existing file with the same name!!")


########
## MAIN
####
def timeIntegrateOptics(inputDN, outputDN, overwrite=False):
	### Preamble
	## Process parameters
	if ( outputDN == None or outputDN == "" ):
		outputDN = inputDN # Write to same directory
	checkArgumentValidity(inputDN, outputDN, overwrite=overwrite)
	outputIsInput = os.path.samefile(inputDN, outputDN)

	## Detect "2D" and "1D" directories, if exists:
	input1DDN = names.joinPaths(inputDN,names.input1DDN)
	input2DDN = names.joinPaths(inputDN,names.input2DDN)
	if ( os.path.exists(input2DDN) ):
		inputDN = input2DDN
		print("Found \"2D\" directory. Using it as input: " + str(inputDN))
	elif( os.path.exists(input1DDN) ):
		inputDN = input1DDN
		print("Found \"1D\" directory. Using it as input: " + str(inputDN))
	else:
		print("Did not find \"2D\" or \"1D\" directory. Using root as input: " + str(inputDN))
	if ( outputIsInput ) :
		outputDN = inputDN
	
	## In the input directory, there should be sorted directories with the microsteps. Detect them:
	RO = re.compile(names.intensitySortedDNRE)
	timeDNList = myRE.getMatchingItems(os.listdir(inputDN), RO)
	print("Found the following major timesteps: " + str(timeDNList))
	if (len(timeDNList) == 0):
		sys.exit("\nERROR: Did not find any sorted major-timestep time directories.")

	## Prepare output directory
	if ( outputIsInput ) :
		# Can we write to the "blurred" directory?
		outputDN = names.joinPaths(outputDN,names.intensityBlurredDN())
		if ( os.path.exists(outputDN) ):
			if ( overwrite ) :
				rmtree(outputDN)
			else:
				sys.exit("\nERROR: Output location '" + outputDN + "' already exists.\n" + \
					 "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n" + \
					 "BE WARNED: This will remove the existing file with the same name!!")
	elif ( os.path.exists(outputDN) and overwrite ) :
		rmtree(outputDN)
	os.makedirs(outputDN)

	## Process every timestep
	for timeDN in tqdm(timeDNList):
		time = timeDN
		timeDN = names.joinPaths(inputDN,timeDN)
		# Count #1D intensities:
		num1D = myRE.countMatchingItems(os.listdir(timeDN),re.compile(names.intensity1DFNRE))
		num2D = myRE.countMatchingItems(os.listdir(timeDN),re.compile(names.intensity2DFNRE))
		numTot = len(os.listdir(timeDN))
		#print("Found for time " + str(timeDN) + ":\n" + \
		#		"num1D = " + str(num1D) + "; num2D = " + str(num2D) + "; numTot = " + str(numTot))
		if(num1D > 0 and num2D == 0):
			outputFN = names.intensity1DFN(time)
		elif(num2D > 0 and num1D == 0):
			outputFN = names.intensity2DFN(time)
		else:
			sys.exit("\nERROR: Input direction '" + str(timeDN) + "' mixes 1D and 2D formatted intensity files.")
		outputFN = names.joinPaths(outputDN,outputFN)
		print(str(timeDN) +  " --> " + str(outputFN))
		# Camera-integrate this timestep:
		integrateOneDir(intensityDN=timeDN, outputName=outputFN, overwrite=overwrite)
	



usageString = "   Sums all intensity files pixel-by-pixel for each major timestep found in the input directory.\n" \
			+ "  It is required that the input directory is already sorted by major timestep with the directory name being the time.\n" \
			+ "   (If not, returns an error.)\n" \
			+ "  This works with both 1D vector and 2D matrix data format for the intensity.\n" \
			+ "  Time-integration requires that time is UNIFORMLY sampled.\n" \
			+ "  usage: " + sys.argv[0] + "  -i <optics results directory> -o <output directory> " \
			+ "[-f]\n" \
			+ "		where:\n" \
			+ "		  -f := force overwrite. WARNING: This will remove any existing directory specified using the -o option\n" \
			+ "		  -o := name of output directory.\n" \
			+ "		  -i := name of input directory (the optics results)\n" 


##############


##############
## Command-Line Interface (CLI)
####
if __name__=='__main__':
	### Read input arguments
	## Command-Line Options
	inputDN = "" # input
	outputDN = "" # output = dir or file, depending on value of -R
	overwrite = False
	## Read
	try:
		opts, args = getopt.getopt(sys.argv[1:],"hfi:o:")
	except getopt.GetoptError:
		print(usageString )
		sys.exit(2)
	for opt, arg in opts:
		if opt == '-h':
			print(usageString )
			sys.exit(0)
		elif opt == '-i':
			inputDN = arg
		elif opt == '-o':
			outputDN = arg
		elif opt == '-f':
			overwrite = True
		else :
			print(usageString )
			sys.exit(2)
	
	### Call main function
	timeIntegrateOptics(inputDN=inputDN, outputDN=outputDN, overwrite=overwrite)




# EOF
