#! /usr/bin/env python3
#
# Takes a N-column datafile. Normalises `--col` column by dividing by its maximum.
#
# Kevin van As
#	06 12 2018: Original

import os.path
import numpy as np
from io import StringIO

class normaliser:
#	def __init__(self, data, col=0):
#		self.col = col # Operate on this column

	def readDataFromFile(self, FN):
		# Sanity Check
		if ( not os.path.exists(FN) ):
			raise ValueError("File \"" + str(FN) + "\" does not exist.")
		# Read datafile
		dataFile = open(FN)
		dataStr = dataFile.read().replace("(", "").replace(")", "").strip()
		#dataStr = dataFile.read().strip()
		data=self.validateData( np.genfromtxt(StringIO(dataStr), skip_header=0) ) # Gives 2D array. Each row has [time, value]
		dataFile.close()
		return data

	def validateData(self, data):
		## Check if ascending Nx2 matrix
		# Type OK?
		if not isinstance(data, np.ndarray):
			raise ValueError("Received data=\"" + str(data) + "\" of type \"" + str(type(data)) +
							", but required a 2D numpy.ndarray with on each row (example for col=2): [?,?,value,?].")
		# Shape OK?
		shape = np.shape(data)
		#print("shape = ", shape, len(shape))
		if not len(shape) == 2:
			raise ValueError("Received data=\"" + str(data) + "\" of type \"" + str(type(data)) + "\" with shape \""+str(shape)+
							"\", which is not a 1D or 2D dataset with per row (example for col=2): [?,?,value,?].")

		## OK!
		return data
		#print("Data = ", data)

	def __call__(self, data, col=1):
		# First check if data is a filename
		if ( data is None or data == "" ):
			raise ValueError("Received data=" + str(data) + ", but it cannot be None or \"\".")
		if ( os.path.exists(data) ): # Is "data" an existing filename?
			# read the file into a numpy.ndarray:
			data = self.readDataFromFile(data)
		else: # Else just assume it is the data directly. self.validateData will do all checks
			data = self.validateData(data)

		data_max = np.max(data[:,col])
		print("data_max="+str(data_max))
		data[:,col] = data[:,col]/data_max
		return data

# Write a 2D array to file if FN is a file.
# Otherwise print to stdout.
def write2DArrayTo(data, FN=None, overwrite=False):
	toFile=True
	if FN == None or FN == "":
		toFile=False
		printFunc=print
	else:
		if os.path.exists(FN) and not overwrite:
			sys.exit("\nERROR: Outputfile '" + FN + "' already exists.\n" +
					 "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n")
		# Create output directory if needed
		DN = os.path.dirname(FN)
		if not DN=="" and not os.path.exists(DN):
			os.mkdir(os.path.dirname(FN))

	if toFile:
		f = open(FN, "w+")
		printFunc=f.write
	for i in range(len(data)):
		lineStr = ""
		for j in range(len(data[i,:])):
			lineStr = lineStr + ("%0.15f " % (data[i,j]) )
		lineStr = lineStr.strip() # Remove last space character #TODO: Arbitrary separator
		if toFile: lineStr = lineStr + "\n"
		printFunc(lineStr)
	if toFile: f.close()
		

if __name__ == '__main__':
	import optparse

	usageString = "usage: %prog -i <datafile> [options]"

	# Init
	parser = optparse.OptionParser(usage=usageString)
	(opt, args) = (None, None)

	# Parse options
	parser.add_option('-i', dest='dataFN',
						   help="Filename of original dataset.")
	parser.add_option('-o', dest='outputFN',
						   help="Name of the output file. Leave blank to print to stdout.")
	parser.add_option('--col', dest='col', type="int", default=int(0),
						   help="What column to operate on (starting from 0).")
	parser.add_option("-f", action="store_true", dest="overwrite", default=False,
						   help="force overwrite output? [default: %default]")
	(opt, args) = parser.parse_args()

	# Run
	dataOut = normaliser()(opt.dataFN, col=opt.col)

	# Write output
	write2DArrayTo(dataOut,FN=opt.outputFN,overwrite=opt.overwrite)




	

# EOF
