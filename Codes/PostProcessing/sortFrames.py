#! /usr/bin/env python3
#
# Take an input directory which has numbers (floats) somewhere in its filenames.
#  By default, it looks for the number right after a character "t", such as in "Intensity_t2.4e-2.png".
#  Sort all those files based on those numbers by prefixing a number to the filenames,
#  which sort correctly by the alphabetical sort of operating systems.
# The prefix is an integer "frame number", incrementing from 0
#  (e.g., if there are 840 files, the numbers will be between 000 and 839).
# 
# Example usage:
#  sortFrames.py -i ./figures -o ./frames -f
# Use -f for overwrite, use -v for verbose. 
#
# Kevin van As
#	18 01 2019: Original
#
# TODO:
#	Rename instead of copy in case that (outputDN == inputDN)

import os.path, shutil
import sys
import re

import math

# Import from optoFluids:
import helpers.regex as myRE
import helpers.printFuncs as myPrint

def sortDir(dirName, numberPrefix="t"):
	# Checks
	if (dirName == "" or dirName == None):
		sys.exit("Input directory must be specified.")

	# Obtain files
	files = os.listdir(dirName)
	numMaxFiles=len(files)

	myPrint.Printer.vprint("Applying regex to files: " + str(files) + ".")

	# Analyse files
	regex = r'.*' + str(numberPrefix) + myRE.group(myRE.floatRE) + r'.*'
	regex = re.compile(regex)
	files = myRE.getMatchingItemsAndGroups(files,regex)
	numMatchFiles=len(files)
	myPrint.Printer.vprint("Found " + str(numMatchFiles) + "/" + str(numMaxFiles) + " files that may be sorted numerically:")
	myPrint.Printer.vprint(files)

	# Sort files
	files = sorted(files, key=lambda item: float(item[1]) )
	myPrint.Printer.vprint("Sorted:")
	myPrint.Printer.vprint(files)
	return myRE.untupleList(files)

def writeWithFrameNumber(sortedFiles, inputDN, outputDN, overwrite=False):
	# Checks
	if ( inputDN  == "" or inputDN  == None):
		sys.exit("Input directory must be specified.")
	if ( outputDN == "" or outputDN == None ):
		sys.exit("Output directory must be specified.")
	if ( inputDN == outputDN ):
		sys.exit("Input directory == output directory is not yet supported.")
	if ( os.path.exists(outputDN) and not overwrite ):
		sys.exit("Output directory already exists, and overwrite=False.")
	if ( len(sortedFiles) < 1 ):
		sys.exit("sortedFiles array is empty: nothing to write.")

	# Create output directory
	if ( os.path.exists(outputDN) ):
		shutil.rmtree(outputDN)
	os.mkdir(outputDN)
	
	# Compute format (number of leading zeroes):
	numFrames = len(sortedFiles)
	numDigits = math.ceil(math.log10(numFrames))
	myPrint.Printer.vprint(str(numFrames) + " -> " + str(math.log10(numFrames)) + " -> " + str(numDigits) )

	# Copy every file:
	i = 0
	for f in sortedFiles:
		# Add zeroes: ( https://docs.python.org/3.1/tutorial/inputoutput.html )
		prefix=str(i).zfill(numDigits) + "_"
		shutil.copyfile(os.path.join(inputDN,f), os.path.join(outputDN,str(prefix)+str(f)))
		#print ( os.path.join(outputDN,str(prefix)+str(f)) )
		i = i + 1



if __name__ == '__main__':
	import optparse

	usageString = "usage: %prog -i <inputFolder> -o <outputFolder> [options]"

	# Init
	parser = optparse.OptionParser(usage=usageString)
	(opt, args) = (None, None)

	# Parse options
	parser.add_option('-i', dest='inputDN',
						   help="Name of the directory which contains the to-be-numerically-sorted files."),
	parser.add_option('-o', dest='outputDN',
						   help="Name of the output directory.")
	parser.add_option("-p", dest="prefix", default="t",
						   help="Prefix before the number. For example, if \"fig_t1e-5\", then choose \"t\".")
	parser.add_option("-v", action="store_true", dest="verbose", default=False,
						   help="verbose [default: %default]")
	parser.add_option("-f", action="store_true", dest="overwrite", default=False,
						   help="force overwrite output? [default: %default]")
	(opt, args) = parser.parse_args()

	myPrint.Printer.verbose = opt.verbose

	writeWithFrameNumber(sortDir(opt.inputDN, opt.prefix), opt.inputDN, opt.outputDN, overwrite=opt.overwrite)



# EOF
