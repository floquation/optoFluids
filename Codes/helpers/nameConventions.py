#! /usr/bin/env python3
#
# This file holds all (file)name conventions that we use in OptoFluids.
#
# The regular expressions (variables suffixed with "RE") can be used for matching.
# The functions and variables suffixed with "DN" (dirname) or "FN" (filename) can be used for writing.
#
# Kevin van As
#	11 10 2018: Original
#	29 11 2018: Implemented myRound for nicely rounded filenames
#	05 12 2018: Fixed myRound to also accept "str"-type input.
# 

import re
import os.path # for joinPaths
from . import regex as myRE

########
## Names for Reading:
## Regular Expressions
####

# Helper functions
def extractTimeAndIndexFromMatch(groups):
	index = float(groups[1]) if len(groups)==3 and groups[1] else "" # index is optional
	time = float(groups[2] if len(groups)==3 else groups[0])
	return (index,time)
# Extract the basename of a filename (i.e., without preceding directories)
def basename(FN):
	return os.path.basename(FN)


# Expression for the time suffix RE, including optional integer index
# (e.g., "_t3_0.500", "_t2.4", or "_t1e-06")
timePrefix = "_t"
timeRE = timePrefix + \
	myRE.group( myRE.group(myRE.intRE, False)+"_" , False) + "?" + \
	myRE.group(myRE.floatRE)

# Particle Positions filenames
particlePositionsFNRE_prefix = \
	myRE.either("pos","particlePositions")
particlePositionsFNRE = particlePositionsFNRE_prefix + \
	timeRE + \
	myRE.optional(".out")

# Intensity filenames
intensity1DFNRE = "Intensity" + \
	timeRE + \
	myRE.optional(".out")
intensity2DFNRE = "Intensity2D" + \
	timeRE + \
	myRE.optional(".out")
intensityFNRE = "Intensity" + \
	myRE.optional("2D") + \
	timeRE + \
	myRE.optional(".out")

# Intensity sorted dirname
intensitySortedDNRE = "^" + myRE.floatRE + "$"
intensityBlurredDNRE = "^blurred$"

# Pixel Coordinates filenames
pixelCoordsFNRE = "PixelCoords.out"
pixelCoords2DFNRE = "PixelCoords2D.out"
pixelCoords2DxFNRE = "PixelCoords2D_x.out"
pixelCoords2DyFNRE = "PixelCoords2D_y.out"
# TODO: Make optional. Difficulty: has a consequence for all files, because they now need to regex-search for pixelCoords.
#pixelCoordsFNRE = "PixelCoords" + myRE.optional(".out")
#pixelCoords2DFNRE = "PixelCoords2D" + myRE.optional(".out")
#pixelCoords2DxFNRE = "PixelCoords2D_x" + myRE.optional(".out")
#pixelCoords2DyFNRE = "PixelCoords2D_y" + myRE.optional(".out")

# Log directory & filenames
logDNRE = "log"
logFNRE = "log" + \
	timeRE + \
	myRE.optional(".out")

## Result directories
# Outer result directories (regular result directory)
resDNRE = "results" + \
	myRE.optional( \
		"_" + \
		myRE.group(r".+") \
	)
# Inner result directories (different instantiations for std calculation)
resInnerDNRE = "results_" + \
	myRE.group(myRE.intRE)



########
## Names for Writing
####

# Helper functions
def fileIndex(time, index=None):
	index = str(index)+"_" if index else "" # index is optional
	return str(index)+str(time)
def joinPaths(a, b):
	return os.path.join(a,b)
def prependDirToFileList(filelist, dirname):
	for i in range(len(filelist)):
		filelist[i] = joinPaths(dirname,filelist[i])
# Round float to 9 significant digits, in exponential notation:
def myRound(value):
	try:
		return float('%.8e' % value)
	except:
		return float('%.8e' % float(value))

# Particle Positions
def particlePositionsFN(time, index=None):
	return "pos" + timePrefix + fileIndex(myRound(time), index)

# Intensity
def intensity1DFN(time, index=None):
	return "Intensity" + timePrefix + fileIndex(myRound(time), index)
def intensity2DFN(time, index=None):
	return "Intensity2D" + timePrefix + fileIndex(myRound(time), index)
def isIntensity1D(FN):
	return myRE.doesItemMatch(FN,re.compile(intensity1DFNRE))
def isIntensity2D(FN):
	return myRE.doesItemMatch(FN,re.compile(intensity2DFNRE))
	

# Sorted Intensity Directories
def intensitySortedDN(time):
	return str(myRound(time))
def intensityBlurredDN():
	return "blurred"

# Pixel Coordinates
pixelCoordsFN = pixelCoordsFNRE 
pixelCoords2DFN = pixelCoords2DFNRE
pixelCoords2DxFN = pixelCoords2DxFNRE
pixelCoords2DyFN = pixelCoords2DyFNRE

# Log directory & filenames
logDN = logDNRE
def logFN(time, index=None, logDir=logDN):
	fn = "log" + timePrefix + fileIndex(myRound(time), index)
	if (logDir and logDir != ""):
		return joinPaths(logDir,fn)
	else:
		return fn

## Result directories
# Outer result directories (regular result directory)
def resDN(suffix=None):
	if suffix:
		return "results_"+str(suffix)
	else:
		return "results"
# Inner result directories (different instantiations for std calculation)
def resInnerDN(suffix):
	errmsg = "Inner result directory requires an integer identifier, but received: "
	assert suffix, errmsg + "None"
	try:
		int(suffix)
	except:
		print(errmsg + str(suffix))
	return "results_"+str(suffix)

# Sorting names
input1DDN="1D"
input2DDN="2D"

# tmp files
def tmpVariablesFN(name, logDir=logDN):
	fn = ".kva_vars_" + str(name) + ".tmp"
	if (logDir and logDir != ""):
		return joinPaths(logDir,fn)
	else:
		return fn
def tmpOpticsInputFN(name, logDir=logDN):
	fn = ".kva_opticsinput" + str(name) + ".tmp"
	if (logDir and logDir != ""):
		return joinPaths(logDir,fn)
	else:
		return fn




# EOF
