#! /usr/bin/env python3
#
# timeIntegrateOptics.py
#
# Computes the intensity sum over all pixels, just like a camera integrates over a finite time period (it cannot measure instantaneously).
#  It is required that the time-dimension has been uniformly sampled. I.e., we sum over the files without any reference to the time.
# Works with both 1D (vector) and 2D (matrix) Intensity files.
#
# Kevin van As
#	23 06 2015: Original
#	16 10 2018: Implemented nameConvention
#				Python3
#	17 10 2018:	Is now an importable module
#
# Known bugs:
#	If "foo" is a file, and -o is "foo/bar", then the code detects that "foo/bar" does not yet exist,
#	only to crash later as it cannot create "foo/bar", since "foo" is a file.
#


# Misc imports
import re # Regular-Expressions
import sys, getopt # Command-Line options
import os.path
from shutil import rmtree

# Numerics
import numpy as np # Matrices

# Import from optoFluids:
import helpers.regex as myRE
import helpers.nameConventions as names







########
## Define functions
####

def getIntensityFiles(fileList):
	intensityFNRO = re.compile(names.intensityFNRE)
	return myRE.getMatchingItemsAndGroups(fileList, intensityFNRO)

def computeTimeRange(timeList):
	tmin=float('inf')
	tmax=-float('inf')
	for time in timeList : 
		time=float(time)
		print("time = " + str(time))
		tmin = min(tmin,time)
		tmax = max(tmax,time)
	step = (tmax-tmin)/(len(timeList)-1)
	return (tmin, step, tmax)


###
# See what integer period fits in the number of files to determine what resolutions we can try
# Then, using those integers, perform the time integration by leaving files out ("coarser resolution")
#
# Tm is the period in integer m. If Tm=1, all files will be taken. If Tm=numFiles, only tmin and tmax are taken.
# Then, T=Tm*step are the steps in time to be used.
# So, if some time, t, is such that (t-tmin)/T=integer, then it should be used for the time integration.
#

# Returns an array of valid resolutions (periods of integer m).
# So res=1 is the best resolution: all files are used,
# whereas res=(numFiles-1) is the worst resolution: only t=tmin and t=tmax are used.
# Convert Tm to the time period, T, by multiplying by dt=(tmax-tmin)/(numFiles-1).
def findValidResolutions(numFiles):
	res=[]
	for m in range(1,numFiles) :
		# See if this m has an integer period
		Tm=float(numFiles-1)/m # period in m, if it is an integer
		if not Tm == float(int(Tm)) : # If not an integer, then not a suitable value for m.
			continue
		# else suitable:
		res.append(Tm)
	return res

def getFilesThatSatisfyRes(fileList, T, timeRange):
	print("Getting files that satisfy period: " + str(T) + ".")
	outList=[]
	tmin = timeRange[0]
	step = timeRange[1]
	intensityFNRO = re.compile(names.intensityFNRE)
	okFileList = myRE.getMatchingItemsAndGroups(fileList, intensityFNRO)
	numFiles=len(okFileList)
	for (intensityFN, time) in okFileList :
		time=float(time)
		print(" Now analysing file: '"+intensityFN+"' with t=" + str(time) + ".")
		# Only use the times that satisfy (t-tmin)/T=integer:
		x=(time-tmin)/T # normalised & origin-shifted coordinate
		xstep=step/T #=Tm
		print(" xstep=",xstep)
		if ( not x == 0 ):
			#print("error=",abs(x-float(int(x)))/xstep)
			if ( abs(x-float(int(x+1e-6)))/xstep > 1e-5 ): # approximately an integer, due to rounding errors
				print("  " + str(time) + " is invalid for T=" + str(T) + ". Ignoring this file.")
#				print("abs(x-float(int(x+1e-6)))/xstep=",abs(x-float(int(x+1e-6)))/xstep)
#				print("abs(x-float(int(x+1e-6)))/x=",abs(x-float(int(x+1e-6)))/x)
				continue # Then invalid time!
		# Else valid:
		outList.append(intensityFN)
	return outList


def averageFiles(DN, fileList):
	firstFile=True
	intensityFNRO = re.compile(names.intensityFNRE)
	for intensityFN in fileList :
		groups = myRE.getMatchingGroups(os.path.basename(intensityFN), intensityFNRO)
		if groups: # If filename matches the regex
			(index, time) = names.extractTimeAndIndexFromMatch(groups)
			print("Now trying to read file: '"+intensityFN+"' with t=",time)
			dataIn = np.loadtxt(open(DN+"/"+intensityFN,"rb"),dtype=float)
			if firstFile:
				# Store info about first file to check whether the subsequent files are consistent
				firstFile=False
				dataAccum=dataIn
				numTerms=1
				fileShape=np.shape(dataIn)
			else:
				# Check whether file is consistent with the first file
				if ( np.shape(dataIn) == fileShape ):
					# Compute the sum of the data files
					dataAccum=dataAccum+dataIn
					numTerms=numTerms+1
				else:
					print("WARNING. '"+intensityFN+"' does not have the same shape as the first file read!!!\n" \
						+ "			First file has a shape: "+str(fileShape)+", whereas this file has shape: "+str(np.shape(dataIn)) \
						+ "\n" \
						+ "			The present file will be IGNORED.\n")
	dataAv=dataAccum/numTerms
	return dataAv

# Writes {1D vector, 2D matrix} "data" to file "outputFN".
def writeData(outputFN, data):
	# Sanity check: only allow 1D vectors and 2D matrices.
	fileShape=np.shape(data)
	if np.size(fileShape)>2 :
		sys.exit("\nERROR: This code does not support matrices that have more than 2 dimensions. Yours has "+str(np.size(fileShape))+".")
	if np.size(fileShape)<1 :
		sys.exit("\nERROR: This code does not support matrices that have less than 1 dimension. Yours has "+str(np.size(fileShape))+".")
	# Start writing
	outputFile = open(outputFN,"w")
	for i1 in range(0, fileShape[0]) :
		line = ""
		if np.size(fileShape)==2:
			for i2 in range(0, fileShape[1]) :
				line = line + str(data[i1,i2]) + " "
		else : # size 1
			line = line + str(data[i1]) + " "
		outputFile.write(line[0:-1] + "\n") # Subtract final spacebar, then write the entire line.
	outputFile.close()





########
## Check Validity of Input Parameters
####
def checkArgumentValidity(intensityDN, outputName, overwrite=False):
	## None checks:
	if ( outputName == None or outputName == "" ):
		print(usageString )
		print("    ERROR: \"outputName\" cannot be an empty string!")
		sys.exit(2)
	if ( intensityDN == None or intensityDN == "" ):
		print(usageString )
		print("    ERROR: input \"intensityDN\" cannot be an empty string!")
		sys.exit(2)
	## Existence checks:
	# Check for existence of the files
	if ( not os.path.exists(intensityDN) ) :
		sys.exit("\nERROR: Inputdir '" + intensityDN + "' does not exist.\n" + \
				 "Terminating program.\n" )
	# Check for existence of the files
	if ( os.path.exists(outputName) and not overwrite ) :
		sys.exit("\nERROR: Output location '" + outputName + "' already exists.\n" + \
				 "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n" + \
				 "BE WARNED: This will remove the existing file with the same name!!")


########
## MAIN
####
def timeIntegrateOptics(intensityDN, outputName, doResolution=False, overwrite=False):
	### Preamble
	## Process parameters
	checkArgumentValidity(intensityDN, outputName, overwrite=overwrite)
	if doResolution:
		outputDN = outputName
	else:
		outputFN = outputName
	## Prepare output
	print("outputName = " + str(outputName))
	if ( os.path.exists(outputName) and overwrite ) :
		if os.path.isfile(outputName) :
			os.remove(outputName)
		elif os.path.isdir(outputName) :
			rmtree(outputName)
		else :
			sys.exit("\nERROR: outputDir or outputFile already exists and is neither a file nor a directory ???\n")
#	else :
#		# else: nothing to be done, because "checkArgumentValidity" checked the existence already.
#		sys.exit("\nERROR: Programming logic mistake.\n This error cannot occur. --> Validity check of output location said OK, but it was not OK.")
	if doResolution :
		os.makedirs(outputDN)
		print("Output directory '" + outputDN + "' was created.")
	### Algorithm
	## Analyse which times we have
	intFilesAndTimes = getIntensityFiles(os.listdir(intensityDN))
	intFilesList = myRE.untupleList(intFilesAndTimes,index=0)
	timesList = myRE.untupleList(intFilesAndTimes,index=1)
	intFilesAndTimes = None
	timeRange = computeTimeRange(timesList)
	numFiles = len(intFilesList)
	step = timeRange[1]
	## Perform the camera integration
	if doResolution :
		resList = findValidResolutions(numFiles)
		print("resList = " + str(resList))
		for res in resList:
			print("\n== res = " + str(res) + " ==")
			intFiles = getFilesThatSatisfyRes( os.listdir(intensityDN), res*step, timeRange )
			print("intFiles = " + str(intFiles))
			dataAv = averageFiles(intensityDN, intFiles)
			#print("dataAv = " +str(dataAv))
			outputFN = names.joinPaths(outputDN, str( int((numFiles-1)/res) ))
			writeData(outputFN,dataAv)
	else: # single resolution
		intFiles = getFilesThatSatisfyRes( os.listdir(intensityDN), 1*step , timeRange) # TODO: This demands a uniform time sampling
		print("intFiles = " + str(intFiles))
		dataAv = averageFiles(intensityDN, intFiles)
		#print("dataAv = " +str(dataAv))
		writeData(outputFN,dataAv)









##############
## Command-Line Interface (CLI)
####
usageString = "   Sums all intensity files pixel-by-pixel. Time-integration requires that time is UNIFORMLY sampled.\n" \
			+ "  usage: " + sys.argv[0] + "  -i <intensityDN> -o <outputFN> " \
			+ "[-f] [-R]\n" \
			+ "		where:\n" \
			+ "		  -f := force overwrite. WARNING: This will remove any existing directory specified using the -o option\n" \
			+ "		  -R := compute the time integration using several resolutions, using (t_max-t_min)/m for all possible m as dt\n" \
			+ "				This only works if the time is perfectly uniformly sampled!\n" \
			+ "				This will output a directory of files, instead of a single file.\n" \
			+ "				The filenames are such that '1' means using only tmin and tmax, and the highest value uses all.\n" \
			+ "				In other words, the higher the value, the finer the time resolution.\n" \
			+ "		  -o := If not -R, output fileName. If -R, output dirName.\n" \
			+ "		  -i := input directory containing all intensity files with uniformly sampled times. NO OTHER FILES ALLOWED.\n" 

if __name__=='__main__':
	### Read input arguments
	## Command-Line Options
	intensityDN = "" # input
	outputDir_or_FileName = "" # output = dir or file, depending on value of -R
	overwrite = False
	doResolution = False
	## Read
	try:
		opts, args = getopt.getopt(sys.argv[1:],"hfi:o:R")
	except getopt.GetoptError:
		print(usageString )
		sys.exit(2)
	for opt, arg in opts:
		if opt == '-h':
			print(usageString )
			sys.exit(0)
		elif opt == '-i':
			intensityDN = arg
		elif opt == '-o':
			outputDir_or_FileName = arg
		elif opt == '-f':
			overwrite = True
		elif opt == '-R':
			doResolution = True
		else :
			print(usageString )
			sys.exit(2)
	
	### Call main function
	timeIntegrateOptics(intensityDN=intensityDN, outputName=outputDir_or_FileName, doResolution=doResolution, overwrite=overwrite)




# EOF
