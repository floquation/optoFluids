#! /usr/bin/env python3
#
# computeSpeckleContrast.py
#
# Computes the speckle contrast, K = sigma_I / <I>.
# Uses LSCI (Local Speckle Contrast Imaging) by computing K in windows, and then taking the mean over those windows.
#
# Kevin van As
#	15 11 2018: Original
#

# Misc imports
#import re # Regular-Expressions
import sys, getopt # Command-Line options
import os.path
#from shutil import rmtree

# Numerics
import numpy as np # Matrices

# Import from optoFluids:
#import helpers.regex as myRE
#import helpers.nameConventions as names



########
## Define functions
####

def speckleContrast(data):
	return np.std(data) / np.mean(data)

blockSize_default=(8,8)
def speckleContrast_Windowing(data, blockSize=None):
	if (blockSize == None): blockSize=blockSize_default
	if (len(blockSize) != 2):
		sys.exit("ERROR: speckleContrast_Windowing requires a tuple of length two for blockSize, but received length "
				+ len(blockSize) + ": " + str(blockSize) + ".")
	C = 0.
	n = 0
	for i in range(0, int( len(data[:, 0]) / blockSize[0] ) ):
		for j in range(0, int( len(data[0, :]) / blockSize[1] ) ):
			# TODO: if len(data) not a multiple of blockSize, then a part of data will currently be ignored.
			dataLocal = data[i * blockSize[0] : (i + 1) * blockSize[0] , j * blockSize[1] : (j + 1) * blockSize[1] ]
			C += speckleContrast(dataLocal)
			n += 1
	return C / float(n)

def readIntensityFile(intFN):
	## None checks:
	if ( intFN == None or intFN == "" ):
		print(usageString )
		sys.exit("    ERROR: input intensity filename cannot be an empty string!")
	## Existence checks:
	if ( not os.path.exists(intFN) ) :
		sys.exit("\nERROR: Inputfile '" + intFN + "' does not exist.\n" + \
				 "Terminating program.\n" )

	data = np.loadtxt(open(intFN,"rb"),dtype=float)
	return data

########
## MAIN
####

def fileSpeckleContrast_Windowing(intFN, blockSize=None):
	data = readIntensityFile(intFN)
	return speckleContrast_Windowing(data=data, blockSize=blockSize)













##############
## Command-Line Interface (CLI)
####
usageString = "Takes an intensity file (in 1D or 2D float format), and computes the speckle contrast: K = STD(I)/<I>.\n" \
			+ "   usage: " + sys.argv[0] + " -i <intensity file name>" \
			+ "[-x blockSizeX -y blockSizeY]\n" \
			+ "   If either -x or -y is omitted, the same value for -x and -y is chosen. If both are omitted, choosing default:" + str(blockSize_default) + "."

if __name__=='__main__':
	### Read input arguments
	## Command-Line Options
	intFN = ""
	blockX = ""
	blockY = ""
	## Read
	try:
		opts, args = getopt.getopt(sys.argv[1:],"hi:x:y:")
	except getopt.GetoptError:
		print(usageString )
		sys.exit(2)
	for opt, arg in opts:
		if opt == '-h':
			print(usageString )
			sys.exit(0)
		elif opt == '-i':
			intFN = arg
		elif opt == '-x':
			blockX = arg
		elif opt == '-y':
			blockY = arg
		else :
			print(usageString )
			sys.exit(2)
	
	if( blockX == "" and blockY == ""):
		blockSize=None
	elif ( blockX == "" ):
		if(blockY.isdigit()):
			blockSize=(int(blockY),int(blockY))
		else:
			sys.exit("-y requires a positive integer, but received: " + str(blockY))
	elif ( blockY == "" ):
		if(blockX.isdigit()):
			blockSize=(int(blockX),int(blockX))
		else:
			sys.exit("-x requires a positive integer, but received: " + str(blockX))
	else:
		if(blockX.isdigit() and blockY.isdigit()):
			blockSize=(int(blockX),int(blockY))
		else:
			sys.exit("-x and -y require positive integers, but received: (" + str(blockX) + "," + str(blockY) + ")")

	### Call main function
	print(fileSpeckleContrast_Windowing(intFN=intFN, blockSize=blockSize))




# EOF
