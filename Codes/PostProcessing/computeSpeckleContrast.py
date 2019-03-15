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
import speckleContrast as SC
import helpers.printFuncs as myPrint

def select(name, *args, **kwargs):
	myPrint.Printer.vprint("selecting: " + str(name))
	if (isinstance(name,str)):
		# String input
		try:
			return RTS.select(SC, str(name), *args, **kwargs)
		except:
			traceback.print_exc()
			raise Exception("Specified \"" + str(name) + "\", which could not be interpreted as a speckleContrast function.\n" + 
							"Valid options are: " + str(RTS.getFunctions(SC)) + ".")
	elif (callable(name)):
		# Callable input
		return name
	else:
		raise Exception("Could not interpret the type (" + type(name) + ") of \"" + str(name) + "\".")

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
	parser.add_option('-i', dest='intFN',
						   help="Filename of intensity file"),
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

	# Compute
	(data, time, index) = optoFluidsIO.readFromFile_Intensity(opt.intFN)
	SC = computeSpeckleContrast(data, opt.SC_func, *SC_args, **SC_kwargs)

	# Output
	print(SC)



# EOF
