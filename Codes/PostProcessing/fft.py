#! /usr/bin/env python3
#
# fft.py
#
# Computes the FFT of a temporal signal.
# Signal may be read from a .csv file from the terminal.
#
# Kevin van As
#	10 04 2019: Original
#
#

# Misc imports
import sys, getopt # Command-Line options
import os.path
import traceback

# Numerics
import numpy as np # Matrices

# Import from optoFluids:
import helpers.IO as optoFluidsIO
#import helpers.RTS as RTS
#import speckleContrast as SC
import helpers.printFuncs as myPrint

def fftfreq(t, half=True):
	#print(t)
	#print("dt = " + str(t[1]-t[0]))
	f = np.fft.fftfreq( len(t), d=(t[1]-t[0]) )
	if half:
		# f = [0, 1, ...,   n/2-1,     -n/2, ..., -1] / (d*n)   if n is even
		# --> index n/2-1 is the last index we want to retain.
		# f = [0, 1, ..., (n-1)/2, -(n-1)/2, ..., -1] / (d*n)   if n is odd
		# --> index (n-1)/2 = n/2-1/2 is the last index we want to retain.
		# For n either even or odd:
		# floor(n/2-1/4)
		# [Ex: n=4, then 4/2-1 = 1, and floor(n/2-1/4)=1; n=5, then (5-1)/2=2, and floor(n/2-1/4)=2.]
		# And then add +1, because the last index is not included when slicing a Python array;
		# The result is:
		f = f[ : int( len(f)/2.0-0.25 )+1 ]
	else:
		f = np.fft.fftshift(f)
	return f

def fft_dim1(y, half=True, zeroMean=False, scale2max1=False):
	assert len(np.shape(y))==1, "The function \"fft_dim1\" only works for a 1D array (=vector), but shape="+str(np.shape(y))+"."
	# Remove constant term?
	if zeroMean: y = y - np.mean(y)
	# FFT:
	Y = np.fft.fft(y)
	# Shift signal / remove negative frequencies:
	if half:
		# see myfftfreq for explanation:
		Y = Y[ : int( len(Y)/2.0-0.25 )+1 ]
	else:
		Y = np.fft.fftshift(Y)
	# Scale to maximum 1:
	if scale2max1:
		Ymax = np.max(abs(Y))
		myPrint.Printer.vprint("Maximum value of fft = " + str(Ymax)) # TODO: info on at what index?
		Y = Y/Ymax
	# Return:
	return Y
def fft_dim2(y, half=True, zeroMean=False, skip_col=None, scale2max1=False):
	assert len(np.shape(y))==2, "The function \"fft_dim2\" only works for a 2D array, but shape="+str(np.shape(y))+"."
	# TODO: Implement multiple axis / directions
	numCols=np.shape(y)[1]
	myPrint.Printer.vprint("fft_dim2: Found " + str(numCols) + " columns to iterate over.")
	Y=() # Collect results in a tuple
	for col in range(numCols):
		if skip_col is not None and col==skip_col:
			myPrint.Printer.vprint("fft_dim2: Skipping column " + str(skip_col) + ".")
			continue # Skip the time/x column
		Ynew = fft_dim1(y[:,col], half=half, zeroMean=zeroMean, scale2max1=scale2max1)
		Y = ( *Y, Ynew )
	Y = np.vstack( Y ).T # Convert tuple-result into 2D numpy array
		# Transposed, because:
		# First index corresponds to "row": iterate over dataset
		# Second index corresponds to "column": which column from dataset
		# Result does not contain the "skip_col" column.
	return Y

def fft(y, half=True, zeroMean=False, skip_col=None, scale2max1=False):
	# TODO: Sanity check on type of y.
	dim=len(np.shape(y))
	myPrint.Printer.vprint("fft: Computing fft with dataset of " + str(dim) + " dimensions:" + str(np.shape(y)) + ".")
	# FFT:
	myPrint.Printer.push()
	if dim==1:
		Y = fft_dim1(y, half=half, zeroMean=zeroMean, scale2max1=scale2max1)
	elif dim==2:
		Y = fft_dim2(y, half=half, zeroMean=zeroMean, skip_col=skip_col, scale2max1=scale2max1)
	else:
		raise Exception("Not yet implemented: fft with an array of more than two dimensions. Received shape = " + str(np.shape(y)) + ".")
	myPrint.Printer.pull()
	return Y


##############
## Command-Line Interface (CLI)
####

if __name__=='__main__':
	import optparse

	usageString = "usage: %prog -i <data.csv> [options]"

	# Init
	parser = optparse.OptionParser(usage=usageString)
	(opt, args) = (None, None)

	# Parse options
	parser.add_option('-i', dest='inFN',
						   help="Filename of .csv file.")
	parser.add_option('-o', dest='outFN',
						   help="Filename of .csv output file, including extension.")
	parser.add_option('--delimiter', dest='delimiter', default=';',
						   help="Delimiter used in the csv file.")
	parser.add_option('--colx', dest='colx', type=int, default=int(0),
						   help="Which column is the x-axis (time)? [default: %default]")
	parser.add_option('--coly', dest='coly', type=int, default=None,
						   help="Which column is the y-axis (data)? If missing, then all columns are iterated over.")
	parser.add_option("--whole", action="store_true", dest="whole", default=False,
						   help="Return the entire FFT, including negative frequencies [default: only return f>=0.]")
	parser.add_option("--zeroMean", action="store_true", dest="zeroMean", default=False,
						   help="Removes the mean of the signal, to prevent a massive peak at zero frequency.")
	parser.add_option("-v", action="store_true", dest="verbose", default=False,
						   help="verbose? [default: %default]")
	parser.add_option("-f", action="store_true", dest="overwrite", default=False,
						   help="overwrite? [default: %default]")
	(opt, args) = parser.parse_args()
	myPrint.Printer.verbose = opt.verbose

	# Sanity
	assert (opt.inFN != None), "Please specify the input filename with -i."
	assert (opt.outFN != None), "Please specify the output filename with -o."
	
	# Input
	(data, header) = optoFluidsIO.readCSV(opt.inFN, delimiter=opt.delimiter)

	# Compute time->freq
	t = data[:,opt.colx]
	f = fftfreq(t, half = not opt.whole)
	header[opt.colx]="f"
	# Compute data->fft
	if opt.coly is None: # If coly is missing, then use all columns
		y = data
		Y = fft(y, half = not opt.whole, zeroMean=opt.zeroMean)
	else: # only compute for coly
		y = data[:,opt.coly]
		Y = fft_dim2(y, half = not opt.whole, zeroMean=opt.zeroMean, skip_col=opt.colx)
		header = [header[opt.colx], header[opt.coly]]
	dataFFT=Y

	# Output
	optoFluidsIO.writeCSV(dataFFT, opt.outFN, dataCol1=f, header=header, delimiter=opt.delimiter, overwrite=opt.overwrite)

	# TODO: Test whether FFT(sin) and FFT(rect) make any sense.






# EOF
#! /usr/bin/env python3
#
# fft.py
#
# Computes the FFT of a temporal signal.
# Signal may be read from a .csv file from the terminal.
#
# Kevin van As
#	10 04 2019: Original
#
#

# Misc imports
