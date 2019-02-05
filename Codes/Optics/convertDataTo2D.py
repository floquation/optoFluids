#! /usr/bin/env python3
#
# Kevin van As
#	20 06 2015: Original
#	15 10 2018: Restructured script with functions.
#				To Python3.
#				Parallel.
#	16 10 2018: Works with outputDir=inputDir --> restructure Intensity & Coord files in "1D" and "2D" directories
#

# Misc imports
import re # Regular-Expressions
import sys, getopt # Command-Line options
import os.path, inspect
import shutil

# Numerics
import numpy as np # Matrices

# Parallelism
import multiprocessing
from multiprocessing import Pool, Value
from functools import partial

# OptoFluids imports
import helpers.regex as myRE
import helpers.nameConventions as names


#filename = inspect.getframeinfo(inspect.currentframe()).filename
#scriptDir = os.path.dirname(os.path.abspath(filename))



########
## Define functions
####

def shiftOrigin(data3D):
	data3D -= data3D[0,:]
#
# Find the span vectors (a and b)
#
def spanVectors(data3D):
	# Define the horizontal and the diagonal
	v_01 = data3D[1,:]
	#print(v_01)
	#print(data3D.shape)
	v_0N = data3D[data3D.shape[0]-1,:]
	#print(v_0N)
	# Define a horizontal and vertical which span the full camera size:
	a = np.dot(v_0N,v_01)/np.dot(v_01,v_01)*v_01
	b = v_0N-a
	#print("a=", a)
	#print("b=", b)
	# The horizontal is along the r1 direction of the camera.
	# The vertical is along a superposition of the r1 and r2 direction, which
	#  is simply equal to the r2 direction if r1 and r2 are orthogonal.
	# I.e., the camera needs not neccesarily be aligned with the b-axis!
	#  The camera can have any shape.
	#  The horizontal is defined as the vector from the zeroth to the first pixel.
	#  The vertical is defined as the vector orthogonal in the plane of the vector from 0 to 1 and 0 to the last pixel.
	#  If the camera is not 2D, no error is raised. The third dimension is simply lost by projection.
	return (a,b)

#
# Project to xyz coordinates (3D) to ab (i.e., span) coordinates (2D)
#
def projectData(data3D, span):
	a=span[0]
	b=span[1]
	data_a = np.dot(data3D,a)/np.dot(a,a)
	#print("shape data_a = ",np.shape(data_a))
	#print("size data_a = ",np.size(data_a))
	#print(data_a.reshape(np.size(data_a),1))
	data2D = data_a.reshape(np.size(data_a),1)
	#print("shape data2D = ",np.shape(data2D))
	#data2D = np.append(data2D,data_a.reshape(2500,1),axis=0)
	data_b = np.dot(data3D,b)/np.dot(b,b)
	#print("shape data_b = ",np.shape(data_b))
	#print("size data_b = ",np.size(data_b))
	data_b = data_b.reshape(np.size(data_a),1)
	#print("data_b = ", data_b)
	data2D = np.append(data2D,data_b,axis=1)
	#print(np.dot(data3D,a)/np.dot(a,a))
	#print("data2D = ", data2D)
	#print("shape=",np.shape(data2D))
	#print("size=",np.size(data2D))
	return data2D

def eps(data2D):
	# Had there been only one dimension, this would be the interpixel distance:
	return (data2D[-1,1]-data2D[0,1])/np.size(data2D[:,1])
	# Therefore, no jump will be larger than that value.
	# (Assumption: uniformly sampled in space.)

#
# Identify the size of the camera in #pixels
#
def getCamSize(data2D):
	# If there is only 1 dimension, we would have this interpixel distance:
	linIncrease = eps(data2D)
	#print("linIncrease = ", linIncrease)

	# When there is more than 1 dimension, there are sudden jumps in the dataset, which are greater than linIncrease.
	# In fact, all jumps are greater than linIncrease.
	# For example, the a-coordinate would jump from 0 to 0.25 to 0.5 to 0.75 to 1,
	#  if we have 5 pixels in the a-direction, while
	#  linIncrease would be 0.125<0.25 if there are 2 pixels in the b-direction.
	
	# x increases gradually. y is constant, and suddenly jumps when x resets from max to min.
	#  Find the first time y makes that jump:
	npix_a = np.nonzero(data2D[:,1]>data2D[0,1]+linIncrease)[0][0]
	npix_b = int(round(np.size(data2D[:,1])/npix_a)) # Should give an exact integer match
	#print("npix = [" + str(npix_a) + ", " + str(npix_b) + "]")
	return (npix_a,npix_b)

def bound01(data, eps):
	# Cap the values between 0 and 1 (which they should be, but they may differ O(eps),
	#  due to rounding errors, which could give interpolation problems (e.g. NaN)).
	# data2D[data2D<0]=0;
	# data2D[data2D>1]=1;
	# Similarly (see determining of npix), the step must neccessarily be greater than or equal to
	#  linIncrease, so:
	#
	data[data>1-eps]=1
	data[data<0+eps]=0

#
# Reshape it such that x increases with column number and y increases with row number:
#  To flip these, use: data2Dx=np.transpose(data2Dx) and data2Dy=np.transpose(data2Dy).
def get2DCoordsComp(data2D, npix, index):
	data2Di = np.reshape(data2D[:,index],(npix[1],npix[0]))
	return np.transpose(data2Di)

## Output functions
def write2DCoordsToFile(data2D, npix, span):
	FN = names.joinPaths(outputDN,names.pixelCoords2DFN)
	a=span[0]
	b=span[1]
	outputFile = open(FN, "w")
	outputFile.write("a= "+str(a/np.linalg.norm(a)) + "\n" )
	outputFile.write("b= "+str(b/np.linalg.norm(b)) + "\n" )
	outputFile.write(str(npix[0]) + " " + str(npix[1]) + "\n" )
	for elem in data2D :
		line = ""
		for elemm in elem :
			line = line + str(elemm) + " "
		outputFile.write(line[0:-1] + "\n")
	outputFile.close()
def write2DCoordsCompToFile(data2Dx, npix, which):
	if which == "x":
		FN = names.joinPaths(outputDN,names.pixelCoords2DxFN)
	elif which == "y":
		FN = names.joinPaths(outputDN,names.pixelCoords2DyFN)
	else:
		return #TODO: throw error
	outputFile = open(FN, "w")
	for i_x in range(0, npix[0]) : # x goes into different rows
		#(note: this is row-column convention, not an x-y-axis convention)
		line = ""
		for i_y in range(0, npix[1]) : # y goes into different columns
			line = line + str(data2Dx[i_x,i_y]) + " "
		outputFile.write(line[0:-1] + "\n")
	outputFile.close()
def writeIntensity2DToFile(data2D, npix, time, index=None):
	outputFile = open(names.joinPaths(outputDN,names.intensity2DFN(time,index)), "w")
	for i_x in range(0, npix[0]) : # x goes into different rows
	#(note: this is row-column convention, not an x-y-axis convention)
		line = ""
		for i_y in range(0, npix[1]) : # y goes into different columns
			line = line + str(data2D[i_x,i_y]) + " "
		outputFile.write(line[0:-1] + "\n")
	outputFile.close()
	
# Worker function which converts the 1D intensity vector to a 2D array
# The tuple npix determines the number of pixels in the a,b directions (in that order)
def processIntensityFile(npix, i_file):
	#proc_id="["+multiprocessing.current_process().name+"] "
	groups = myRE.getMatchingGroups(os.path.basename(i_file), intensityFNRO)
	if groups: # If filename matches the regex
		(index, time) = names.extractTimeAndIndexFromMatch(groups)
		#print("index = " + str(index) + "; time = " + str(time))
		dataLin = np.fromfile(i_file,dtype=float,count=-1,sep=" ")
		#print(dataLin)
		data2D = np.reshape(dataLin,(npix[1],npix[0]))
		data2D = np.transpose(data2D) # After this line, the first index of data2D refers to the a-coordinate and the second to the b-coordinate
		# Output to file
		writeIntensity2DToFile(data2D, npix, time, index)



# Restructure the input directory such that all Intensity files & the PixelCoordinates file
# get moved to (a newly created) "1D" directory, and creates a "2D" directory for the 2D output.
def restructureInputDir(inputDN):
	input1DDN = names.joinPaths(inputDN,names.input1DDN)
	if ( not os.path.exists(input1DDN) ):
		os.makedirs(input1DDN)
		expr = myRE.either(myRE.either(names.intensity1DFNRE, names.pixelCoordsFNRE), names.intensitySortedDNRE)
		RO = re.compile(expr)
		files = myRE.getMatchingItems(os.listdir(inputDN), RO)
		print("(restructureInputDir) Moving files: " + str(files))
		for item in files:
			FN = names.joinPaths(inputDN,item)
			shutil.move(FN,input1DDN)
	input2DDN=names.joinPaths(inputDN,names.input2DDN)
	if ( os.path.exists(input2DDN) ) :
		shutil.rmtree(input2DDN)
	os.makedirs(input2DDN)







########
## Process Input Arguments
####
# Command-Line Options
inputDN = ""
outputDN = ""
numCores = 1
overwrite = False
outputIsInput = False
#
usageString = "This script automatically loops over all intensity files in the given directory (-i) and then writes them to a different format in the output directory (-o)\n" \
			+ "Filename for coordinates: 'PixelCoords.out'. Filename for intensity: 'Intensity_tFLOAT.out'\n" \
			+ "   usage: " + sys.argv[0] + " -i <intensity and pixelCoords dirName> -o <outputDir for 2D data> " \
			+ "[-f]" \
			+ "[-C <number of cores to use>]" \
			+ "\n" \
			+ "		where:\n" \
			+ "		  -f := force overwrite. WARNING: This will remove any existing directory specified using the -o option\n" \
			+ "		  -C defaults to '1' (serial run). Use '0' to use all available system cores\n"
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
	elif opt == '-C':
		numCores = int(arg)
	elif opt == '-f':
		overwrite = True
	else :
		print(usageString )
		sys.exit(2)
#
if (inputDN == "") :
	print(usageString )
	print("    Note: dir-/filenames cannot be an empty string:")
	print("		inputDN="+inputDN)
	sys.exit(2)
#
if (outputDN == ""):
	outputDN=inputDN
	outputIsInput=True





########
## Check Validity of Input Parameters
####
# Check for existence of the files
if ( not os.path.exists(inputDN) ) :
	sys.exit("\nERROR: Inputdir '" + inputDN + "' does not exist.\n" + \
			 "Terminating program.\n" )
if ( not outputIsInput and os.path.exists(outputDN) and not overwrite ) :
	sys.exit("\nERROR: Outputdir '" + outputDN + "' already exists.\n" + \
			 "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n" + \
			 "BE WARNED: This will remove the existing directory with the same name as the Outputdir!")

# Check whether input has a "1D" directory to store Intensity/PixelCoords:
intInputDN=inputDN
input1DDN=names.joinPaths(inputDN,names.input1DDN)
if ( os.path.exists(input1DDN) ):
	intInputDN=input1DDN

# Check whether we are trying to write to an already-existing "2D" directory:
input2DDN=names.joinPaths(inputDN,names.input2DDN)
if ( outputIsInput and os.path.exists(input2DDN) and not overwrite ):
	sys.exit("\nERROR: Outputdir '" + input2DDN + "' already exists.\n" + \
			 "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n" + \
			 "BE WARNED: This will remove the existing directory with the same name as the Outputdir!")

# Check whether input exists
pixelCoordsFN = names.joinPaths(intInputDN,names.pixelCoordsFN)
if ( not os.path.exists(pixelCoordsFN) ) :
	sys.exit("\nERROR: Inputfile for the PixelCoords '" + pixelCoordsFN + "' does not exist.\n" + \
			 "Terminating program.\n" )


### All input is now verified. Now start changing the directory structure. ###





########
## Prepare Output Directory
####
if (not outputIsInput):
	# Create output directory (note: it was already checked that we can safely continue)
	if ( os.path.exists(outputDN) and overwrite ) :
		shutil.rmtree(outputDN)
	os.makedirs(outputDN)
	print("Output directory '" + outputDN + "' was created.")
else: # OutputDir = InputDir
	# Restructure input directory to prepare for the ouput
	restructureInputDir(inputDN)
	intInputDN=names.joinPaths(inputDN,names.input1DDN)
	pixelCoordsFN = names.joinPaths(intInputDN,names.pixelCoordsFN)
	outputDN=names.joinPaths(inputDN,names.input2DDN)





########
## Restructure PixelCoordinates
####

# Read
dataRegex = re.compile(myRE.floatREx3)
data3D = np.fromregex(pixelCoordsFN,dataRegex,dtype='f')
print("data3D original = ", data3D)
shiftOrigin(data3D)
print("data3D or.shift = ", data3D)
# Convert to 2D
span = spanVectors(data3D)
data2D = projectData(data3D, span)
print("data2D = ", data2D)
#print("data2D[2][:] = ", data2D[2][:])
bound01(data2D, eps(data2D)*0.999)
print("data2D bounded = ", data2D)
npix = getCamSize(data2D)
print("npix = ", npix)
data2Dx = get2DCoordsComp(data2D, npix, 0)
data2Dy = get2DCoordsComp(data2D, npix, 1)
# Write
write2DCoordsToFile(data2D, npix, span)
write2DCoordsCompToFile(data2Dx, npix, "x")
write2DCoordsCompToFile(data2Dy, npix, "y")




########
## Process the intensity files
####

intensityFNRO = re.compile(names.intensity1DFNRE)
## First simply count the number of matches, such that the user can anticipate if this gives an unexpected result.
inputList=os.listdir(intInputDN)
num_total=len(inputList)
intFilesList=myRE.getMatchingItems(inputList,intensityFNRO)
names.prependDirToFileList(intFilesList,intInputDN)
num_valid=len(intFilesList)
print("Number of valid Intensity files found in \"" + \
	intInputDN + "\" (rel. to total number) = " + \
	str(num_valid) + "/" + str(num_total))
## Now start iterating over the files to convert the 1D vector data to a 2D array of size (npix_a, npix_b)
if(numCores > 0):
	pool = Pool(processes=numCores)
else:
	pool = Pool()
func = partial(processIntensityFile, npix)
pool.map(func, intFilesList)






# EOF
