#! /usr/bin/env python3
#
# computeSpeckleContrast.py
#
# Computes the speckle contrast, K = sigma_I / <I>.
# Uses LSCI (Local Speckle Contrast Imaging) by computing K in windows, and then taking the mean over those windows.
#
# Kevin van As
#	15 11 2018: Original
#	05 04 2019: Implemented enhanced RTS "select" functionality by deleting lines that are now no longer necessary.
#	14 05 2019:	Now accepts a result directory as -i, as well as an intensity file. --> Bram Simons
#
# TODO:
# - If intensity1D is read, windowing cannot be used, unless we automatically detect pixelCoords and reshape.
#	--> Enforce 2D read? Raise warning if 1D is found, as "basic" SCfunc may still be used?
#

# Misc imports
import sys, getopt # Command-Line options
import os.path
import traceback

# Numerics
import numpy as np # Matrices

# Import from optoFluids:
import helpers.IO as optoFluidsIO
import helpers.RTS as RTS
import helpers.regex as myRE
import helpers.nameConventions as names
import speckleContrast as SC
import helpers.printFuncs as myPrint

def select(name, *args, **kwargs):
	return RTS.select(SC, str(name), *args, **kwargs)

def computeSpeckleContrast(data, SC_func, *args, **kwargs):
	SCfunc = select(SC_func, *args, **kwargs) # RTS
	SC = SCfunc(data) # Call computing function
	return SC


##############
## Command-Line Interface (CLI)
####

if __name__=='__main__':
	import optparse

	usageString = "usage: %prog -i <intensity filename> [options]"

	# Init
	parser = optparse.OptionParser(usage=usageString)
	(opt, args) = (None, None)

	# Parse options
	parser.add_option('-i', dest='inFDN',
						   help="Name of results directory, or single intensity filename"),
	parser.add_option('-t', dest='SC_func', default="basic",
						   help="Name of the speckle contrast function: " + str(RTS.getFunctions(SC)) + ". [default: %default]"),
	parser.add_option('--args', dest='SC_args',
						   help="Required arguments for the chosen speckle contrast function (if any). " +
							"Separate the parameters with a semicolon (e.g., --args \"a;b\").")
	parser.add_option("-v", action="store_true", dest="verbose", default=False,
						   help="verbose [default: %default]")
	(opt, args) = parser.parse_args()
	myPrint.Printer.verbose = opt.verbose
	
	# Pre-parse arguments
	(SC_args, SC_kwargs) = RTS.multiArgStringToArgs(opt.SC_args)

	# Detect whether input is an intensity file or a directory:
	if myRE.doesItemMatch(os.path.basename(opt.inFDN), myRE.compile(names.intensityFNRE)):
		# Then input is an intensity filename
		# Read input:
		(data, time, index) = optoFluidsIO.readFromFile_Intensity(opt.inFDN)
		# Compute and output:
		print( computeSpeckleContrast(data, opt.SC_func, *SC_args, **SC_kwargs) )
	else:
		# Else input is not an intensity filename. Check whether it is a result directory.
		# Get multiple result directories (if any):
		resultDNs = optoFluidsIO.getResultDirs(opt.inFDN)
		# Compute:
		SCarray = []
		for resDN in resultDNs:
			# TODO: How to select the appropriate intensity file? CLI?
			try: # Prioritize blurred:
				argument = resDN + '/2D/blurred/Intensity2D_t0.0'
				(data, time, index) = optoFluidsIO.readFromFile_Intensity(argument)
			except: # No blurred, so unsorted:
				argument = resDN + '/2D/Intensity2D_t0.0'
				(data, time, index) = optoFluidsIO.readFromFile_Intensity(argument)
			SCarray.append(computeSpeckleContrast(data, opt.SC_func, *SC_args, **SC_kwargs))
		if (len(SCarray) > 1):
			SCarray.insert(0,np.std(SCarray))
			SCarray.insert(0,np.mean(SCarray))
			# Output
			print("mean","std",*range(1,len(SCarray)-1),sep=';')
			print(*SCarray,sep=';')
		else:
			print(*SCarray)



# EOF
