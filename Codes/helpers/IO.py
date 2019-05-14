#! /usr/bin/env python3
#
# This file handles all logic regarding reading and writing optoFluids files,
# taking care automatically of all nameConventions.
#
#
# Some notes:
# - helpers.nameConventions holds the conventional filename formats etc.; this script performs the I/O operations.
# - Final line should also have \n in a Unix textfile! https://unix.stackexchange.com/questions/18743/whats-the-point-in-adding-a-new-line-to-the-end-of-a-file
# - writing of 2D files is with a (row, column) convention, such that "first index" = "x" = vertical.
#
# Kevin van As
#	11 02 2019: Original
#	18 02 2019: writeToFile_Coords2D now takes either (N,2) 1D vector format or (A,B) tuple of two meshgrids format.
#				readFromFile_Coords2D_header reads the span (a and b direction vector) and npix.
#	04 04 2019: Added readCSV functionality
#	10 04 2019:	Added writeCSV functionality
#
# TODO:
# - auto detect pixelCoords location?
#

# Misc imports
import re # Regular-Expressions
#import sys
#import getopt # Command-Line options
import os.path#, inspect
import os.listdir
#import shutil

import csv

# Numerics
import numpy as np # Matrices

# OptoFluids imports
import helpers.regex as myRE
import helpers.nameConventions as names


####
## Helper functions
########

# Helper function which checks if the file exists.
# Raise an exception if file does not exists.
def fileExists(FN):
	if not os.path.isfile(FN):
		raise Exception("Input file \""+str(FN)+"\" not found, so cannot read it.")
	return True

# Helper function which checks if the file does not already exists.
# Raise an exception if the file already exists and overwrite=False.
def fileNotAlreadyExists(FN, overwrite=False):
	if ( os.path.exists(FN) and not overwrite ):
		raise Exception("Error: output file \"" + str(FN) + "\" already exists, but overwrite=False.")
	return True

# Helper function which matches FN against regex FNRE.
# If successful, returns the matched groups (or an empty tuple).
# If unsuccessful, raise an exception instead.
def doRegexMatch(FN, FNRE):
	FNRO = re.compile(FNRE)
	groups = myRE.getMatchingGroups(names.basename(FN), FNRO)
	if groups: # If filename matches the regex
		return groups
	else:
		if not myRE.doesItemMatch(names.basename(FN), FNRO):
			raise Exception(
				"File \""+str(FN)+"\" does not satisfy the regex: \"" + \
				str(FNRE) + \
				"\"."
			)
	return ()

# Helper function which reshapes a 1D vector data to 2D with shape (N[0],N[1])
def reshapeTo2D(data, N):
	if(len(N)!=2): raise Exception("in reshapeTo2D: expected len(N)=2, but received N="+str(N)+".")
	data2D = np.reshape(data,(N[1],N[0]))
	data2D = np.transpose(data2D)
	return data2D 
	
####
## Pixel Coordinates
########


## Writing

# Writes PixelCoords2D.out, which is the pixel coordinates file in 2D (a,b) format.
#
# Usage example:
#	writeToFile_Coords2D(pixelCoords, outputDN, span, npix)
# where:
#   span is ( span_a, span_b ), and span_a and span_b are three-vectors defining the a and b direction. They may be read from PixelCoords2D.out using "readFromFile_Coords2D_header".
#   npix is ( Na, Nb ) the number of pixels in both directions
#   outputDN is the output directory name
#   data contain the (a,b) pixel coordinates in either (N,2) vector format, or (2,(Na,Nb)) tupled meshgrid format: (A,B), where A and B are meshgrids.
def writeToFile_Coords2D(data, outputDN, span, npix, overwrite=False, suffix=""):
	outputFN = names.joinPaths(outputDN,names.pixelCoords2DFN) + str(suffix)
	# Sanity:
	assert (fileNotAlreadyExists(outputFN,overwrite))
	assert (len(span)==2), "In writeToFile_Coords2D: len(span) must be 2."
	assert (len(npix)==2), "In writeToFile_Coords2D: len(npix) must be 2."

	## Detect whether "data" is in 1D format or in 2D (meshgrid) format:
	shape = np.shape(data)
	#print("data shape = " + str(shape))
	if (len(shape) == 3):
		assert(shape[0] == 2), "In writeToFile_Coords2D: expected a tuple of length two: (A,B), but received shape: " + str(shape) + "."
		assert(np.shape(data[0]) == np.shape(data[1])), "In writeToFile_Coords2D: meshgrid (A,B), must have the same shape, but received shape(meshgrid): " + str(np.shape(data[0])) + " and " + str(np.shape(data[1])) + "."
		assert(npix == np.shape(data[0])), "In writeToFile_Coords2D: meshgrid (A,B) must have the shape of npix, but received shape(meshgrid)=" + str(np.shape(data[0])) + ", npix=" + str(npix) + "."
		# We have a tuple (A,B) with A and B meshgrids.
		dataType=2
		#print("Found 2D meshgrid data set!")
		#print(np.shape(data[0]))
		#print(np.shape(data[1]))
		#print(npix)

	elif (len(shape) == 2):
		assert(shape[1] == 2), "In writeToFile_Coords2D: expected a 1D vector with two coordinates, but it has " + str(shape[1]) + " coordinates."
		assert(npix[0]*npix[1] == shape[0]), "In writeToFile_Coords2D: expected a 1D vector with length equal to the number of pixels (" + str(npix) + " = " + str(npix[0]*npix[1]) + "), but it had length " + str(shape[0]) + "."
		# We have a 1D vector of length (npix[0]*npix[1]) with 2 coordinates.
		dataType=1
		#print("Found 1D data set!")

	else:
		raise Exception("writeToFile_Coords2D received data that it cannot interpret. Expected either:\n" + \
			"  - matrix of shape (number of pixels, 2), giving the (a,b) coordinates in order with the a-direction incrementing first" + \
			"  - tuple of length two holding (A,B), where A and B are meshgrids of shape (npix_a, npix_b)." \
		)

	# Write file header:
	outputFile = open(outputFN, "w")
	a=span[0]
	b=span[1]
	outputFile.write("a= "+str(a/np.linalg.norm(a)) + "\n" )
	outputFile.write("b= "+str(b/np.linalg.norm(b)) + "\n" )
	outputFile.write(str(npix[0]) + " " + str(npix[1]) + "\n" )
	# Write the 2D data to file in 1D format (i.e., on each line the (a,b) coordinate):
	if dataType == 1:
		for elem in data :
			line = ""
			for elemm in elem :
				line = line + str(elemm) + " "
			outputFile.write(line[0:-1] + "\n")
	elif dataType == 2:
		for i_b in range(0,npix[1]) :
			for i_a in range(0,npix[0]) :
				outputFile.write(str(data[0][i_a,i_b]) + " " + str(data[1][i_a,i_b]) + "\n")
	else:
		raise Exception("In writeToFile_Coords2D: programming logic error. This cannot occur.")

	# And finally close the file:
	outputFile.close()

# Like "writeToFile_Coords2D", but now writes the single-coordinate-2D-matrix-format file, as specified by the index "which".
def writeToFile_CoordsComp2D(data1D, outputDN, which, npix, overwrite=False, suffix=""):
	# Select the right coordinate:
	which = int(which)
	if which == 0:
		outputFN = names.joinPaths(outputDN,names.pixelCoords2DxFN) + str(suffix)
	elif which == 1:
		outputFN = names.joinPaths(outputDN,names.pixelCoords2DyFN) + str(suffix)
	else:
		raise Exception("Error: Tried to access coordinate \"" + str(which) + "\", but only \"0\" and \"1\" are implemented.")
	# Sanity:
	assert (fileNotAlreadyExists(outputFN,overwrite))

	# Extract component, and reshape to 2D:
	#  Reshape it such that x increases with column number and y increases with row number:
	#  To flip these, use: data2Dx=np.transpose(data2Dx) and data2Dy=np.transpose(data2Dy).
	data2Di = reshapeTo2D(data1D[:,which],npix)

	# Write to file in 2D format (matrix shape that holds one component for every pixel):
	outputFile = open(outputFN, "w")
	for i_x in range(0, npix[0]) : # x goes into different rows
		#(note: this is row-column convention, not an x-y-axis convention)
		line = ""
		for i_y in range(0, npix[1]) : # y goes into different columns
			line = line + str(data2Di[i_x,i_y]) + " "
		outputFile.write(line[0:-1] + "\n")
	outputFile.close()
def writeToFile_CoordsComps2D(data1D, outputDN, npix, overwrite=False, suffix=""):
	for i in range(0, len(data1D[0,:])):
		writeToFile_CoordsComp2D(data1D, outputDN, i, npix, overwrite=overwrite, suffix=suffix)


## Reading
	
# Reads PixelCoords.out, which is the original 3D (x,y,z) pixel coordinates file.
# Returns a 2D numpy array of size (numPixels,3).
def readFromFile_CoordsXYZ(FN, forceRead=False):
	# Sanity check filename:
	if not forceRead:
		doRegexMatch(FN,names.pixelCoordsFNRE)
	assert (fileExists(FN))

	# Read (x,y,z) coordinate:
	#dataRegex = myRE.compile(myRE.withinSpaces(myRE.floatREx3))
	dataRegex = myRE.compile(myRE.floatREx3)
	coords = np.fromregex(FN,dataRegex,dtype='f')
	# Return the array
	return coords

# Reads PixelCoords2D.out, which contain the pixel coordinates in (a,b) coordinates: normalised between 0 and 1.
# Returns a tuple of size two, (A,B), containing 2D matrices ("meshgrids").
# The a-direction increments in the first index; b in the second.
# Usage example:
#	(A,B) = readFromFile_CoordsAB(FN) # extract meshgrids of coordinates
#	npix = np.shape(A) # first tuple index = a direction; second is b
def readFromFile_CoordsAB(FN, forceRead=False):
	# Sanity check filename:
	if not forceRead:
		doRegexMatch(FN,names.pixelCoords2DFNRE)
	assert (fileExists(FN))

	# Read coordinates:
	coords = np.loadtxt(FN,delimiter=' ', skiprows=2) # skip "a=" and "b=" line
	if(len(coords[0,:]) != 2):
		raise Exception("PixelCoordinates \"" + str(FN) + "\" does not have two columns. Invalid file format - cannot be read.")

	# Extract information into parts:
	npixa = int(coords[0,0])
	npixb = int(coords[0,1])
	A = coords[1:,0].reshape((npixb,npixa))
	B = coords[1:,1].reshape((npixb,npixa))
	A = A.T
	B = B.T

	#print("A=" + str(A))
	#print("B=" + str(B))
	#print("npixa=" + str(npixa) + "; npixb=" + str(npixb))

	return (A,B)
	# Tip: you can get npixa and npixb like this in the caller function:
	# npix=np.shape(A) # first tuple index = a direction; second is b

# Reads the header (first three lines) of PixelCoords2D.out
# Usage example:
#	(npix, span) = readFromFile_CoordsAB_header(FN)
# Then, span[0] is the a-direction vector, span[1] is the b-direction vector,
# and npix = (Na, Nb) are the number of pixels in both directions.
def readFromFile_CoordsAB_header(FN, forceRead=False):
	# Sanity check filename:
	if not forceRead:
		doRegexMatch(FN,names.pixelCoords2DFNRE)
	assert (fileExists(FN))

	# Read header from coordinates file:
	coordsFile = open(FN)
	coordsFile_row1 = coordsFile.readline() # "a= [%f %f %f]" line
	coordsFile_row2 = coordsFile.readline() # "b= [%f %f %f]" line
	coordsFile_row3 = coordsFile.readline() # "%i %i" line, yielding (Na, Nb)
	coordsFile.close()

	# Analyse the read Strings:
	row1_RE = "a= \[" + myRE.withinSpaces(myRE.floatREx3) + "\]" 
	row1_RO = myRE.compile(row1_RE)
	span_a_str = myRE.getMatchingGroups(coordsFile_row1, row1_RO)
	row2_RE = "b= \[" + myRE.withinSpaces(myRE.floatREx3) + "\]" 
	row2_RO = myRE.compile(row2_RE)
	span_b_str = myRE.getMatchingGroups(coordsFile_row2, row2_RO)
	row3_RO = myRE.compile(myRE.group(myRE.intRE) + " " + myRE.group(myRE.intRE))
	npix_str = myRE.getMatchingGroups(coordsFile_row3, row3_RO)
	
	#print(span_a)
	#print(span_b)
	#print(npix)

	# Convert str tuple to ints/floats tuple:
	npix=()
	for item in npix_str:
		npix += (int(item),)
	span_a=()
	for item in span_a_str:
		span_a += (float(item),)
	span_b=()
	for item in span_b_str:
		span_b += (float(item),)

	# Done!
	return (npix, (span_a,span_b))

	

####
## Intensity
########

## Writing

def writeToFile_Intensity2D(data2D, outputDN, time, index=None, overwrite=False, suffix=""):
	# Generate output filename:
	outputFN = names.joinPaths(outputDN,names.intensity2DFN(time,index)) + str(suffix)
	# Sanity:
	assert (fileNotAlreadyExists(outputFN,overwrite))
	# Write data to file:
	outputFile = open(outputFN, "w")
	for i_x in range(0, len(data2D[:,0]) ) : # x (a-direction) goes into different rows = vertical
		#(note: this is row-column convention, not an x-y-axis convention, such that "first index" = "x")
		line = ""
		for i_y in range(0, len(data2D[0,:])) : # y (b-direction) goes into different columns = horizontal
			line = line + str(data2D[i_x,i_y]) + " "
		outputFile.write(line[0:-1] + "\n")
	outputFile.close()


## Reading


# Takes a list of filenames.
# Return only those files that satisfy the intensity filename convention.
# No files? Returns an empty array (length zero).
def getIntensityFilesAndGroups(fileList):
	intensityFNRO = re.compile(names.intensityFNRE)
	return myRE.getMatchingItemsAndGroups(fileList, intensityFNRO)
def getIntensityFiles(fileList):
	intensityFNRO = re.compile(names.intensityFNRE)
	return myRE.getMatchingItems(fileList, intensityFNRO)

# Read intensity file in 1D format, and optionally reshapes it to 2D.
#
# intFN := name of the intensity file (1D format)
# N is a tuple of the form (Na,Nb):
#  Na := number of pixels in the first (a) direction
#  Nb := number of pixels in the second (b) direction
#  If None, then return a 1D vector. If (Na,Nb) reshape data to a 2D array.
# forceRead := skip regex check on filename, and just read it.
#  may cause wrong results if the caller is not careful, evidently.
# @return: ( 1D or 2D numpy array, time, index )
def readFromFile_Intensity1D(FN, N=None, forceRead=False):
	# Sanity (and read (time,index) if possible):
	try:
		#(time, index) = doRegexMatch(FN,names.intensity1DFNRE)
		(index, time) = names.extractTimeAndIndexFromMatch(doRegexMatch(FN,names.intensity1DFNRE))
	except Exception as error:
		if(forceRead):
			(time, index) = (None, None)
		else:
			raise Exception(str(error) + " And forceRead=False.")
	assert (fileExists(FN))

	# Read data:
	data = np.fromfile(FN,dtype=float,count=-1,sep=" ")
	if N != None: # then reshape to 2D (matrix)
		# Word of caution: if intFN was already a 2D file, the result will be wrong.
		#  That is, if Na=Nb, the result is simply transposed (which it shouldn't have been),
		#  whereas if Na!=Nb, the result will be scrambled: completely wrong.
		#  Solution: use the readFromFile_Intensity2D function, instead of using forceRead=True on this one!
		data2D = reshapeTo2D(data,N)
		return (data2D, time, index)
	else: # else leave in 1D (vector) format
		return (data, time, index)

	
# Read intensity file in 2D format.
#
# FN := name of the intensity file (2D format)
# forceRead := skip regex check on filename, and just read it.
#  may cause wrong results if the caller is not careful, evidently.
# @return: ( 2D numpy array, time, index )
def readFromFile_Intensity2D(FN, forceRead=False):
	# Sanity (and read (time,index) if possible):
	try:
		#(time, index) = doRegexMatch(FN,names.intensity2DFNRE)
		(index, time) = names.extractTimeAndIndexFromMatch(doRegexMatch(FN,names.intensity2DFNRE))
	except Exception as error:
		if(forceRead):
			(time, index) = (None, None)
		else:
			raise Exception(str(error) + " And forceRead=False.")
	assert (fileExists(FN))

	# Read data:
	data = np.loadtxt(open(FN,"rb"),dtype=float)
	return (data, time, index)

# Automatically calls the correct intensity reader: 1D or 2D.
#
# FN := name of the intensity file (1D format or 2D format)
# N is a tuple of the form (Na,Nb):
#  Na := number of pixels in the first (a) direction
#  Nb := number of pixels in the second (b) direction
#  If None, then return a 1D array. If (Na,Nb) reshape data to 2D.
# forceRead := skip regex check on filename, and just read it
# @return: ( 1D or 2D numpy array, time, index )
def readFromFile_Intensity(FN, N=None, forceRead=False):
	FNRO = re.compile(names.intensity2DFNRE)
	success = myRE.doesItemMatch(names.basename(FN), FNRO)
	if success: # Is a 2D file!
		return readFromFile_Intensity2D(FN, forceRead)
	else: # Is not a 2D file. Let the 1D function handle the further checks.
		return readFromFile_Intensity1D(FN, N, forceRead)
	







####
## CSV files
########


## Writing


# Write a 1D or 2D array data to (csv) file, including:
# - optional prepend of a first (x) column
# - optional header
def writeCSV(data, outputFN, dataCol1=None, header=None, delimiter=';', overwrite=False):
	# Sanity:
	assert (fileNotAlreadyExists(outputFN,overwrite))
	assert ( dataCol1 is None or np.shape(data)[0]==len(dataCol1) ), "dataCol1 does not have the same number of entires / the same length as \"data\"."

	# Work with tuples, instead of (1D/2D) arrays:
	data = tuple(data.T)
	if dataCol1 is not None:
		if len(np.shape(data))==1:
			data = (dataCol1, data)
		elif len(np.shape(data))==2:
			data = (dataCol1, *data)
		else:
			raise Exception("Cannot write data with " + 
							str(len(np.shape(data))) + " dimensions.")
	if len(np.shape(data)) > 1:
		data=tuple(zip(*data)) # Tranpose

	# Write data to file:
	# (1D data)
	if len(np.shape(data)) == 1:
		# Treat writing a vector differently, as "csv" library cannot handle it:
		writeVector(data, outputFN, header=header, overwrite=overwrite)
		return
	# (2D data)
	with open(outputFN, mode='w') as outputFile:
		writer = csv.writer(outputFile, delimiter=delimiter)
		# Write header (if it's there):
		if header is not None and not (type(header) is str and header == ""):
			writer.writerow(header)
		# Write data rows:
		for row in data:
			writer.writerow( row )

# Write a 1D array (=vector) to a datafile:
def writeVector(vector, outputFN, header=None, overwrite=False):
	# Sanity:
	assert (fileNotAlreadyExists(outputFN,overwrite))
	assert (len(np.shape(vector))==1), "\"writeVector\" requires a 1D array (=vector) input."
	if header is None: # np.savetxt requires empty string; not NoneType.
		header=""
	# Write data to file:
	np.savetxt(outputFN, vector, header=header)


## Reading


# Reads a CSV file
def readCSV(FN, delimiter=';', skip_header=1):
	data = np.genfromtxt(FN, delimiter=delimiter, dtype=float, skip_header=skip_header)
	header = np.genfromtxt(FN, delimiter=delimiter, dtype=str, skip_footer=len(data))
	return (data, header)
def readCSVs(FNs, delimiter=';', skip_header=1):
	data=() # Read multiple data sets into a list (n-tuple); convert to 3D array later.
	header=()
	for i, inFN in enumerate(FNs):
		# Read single file:
		data0, header0 = readCSV(inFN, delimiter=delimiter, skip_header=skip_header)
		# Collest multiple files in tuple:
		data = data + (data0,)
		header = header + (header0,)
	data = np.dstack(data) # Convert list of 2D arrays to a 3D array
	return (data, header)



####
## Result directories
########


## Reading

def getResultDirs(mainDir):
	# Sanity:
	# TODO

	# List content of mainDir:
	content = sorted(os.listdir(mainDir))
	innerResDNs = getMatchingItems(content, myRE.compile(names.resInnerDNRE))
	if (len(innerResDNs) > 0):
		# We must have inner result directories
		# so return an array of them
		return innerResDNs
	else:
		# There are no inner result directories
		# so just return the main one
		return [mainDir]





# EOF
