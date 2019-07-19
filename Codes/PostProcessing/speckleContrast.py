#! /usr/bin/env python3
#
# speckleContrast.py
#
# Holds severeal run-time selectable functions to compute the speckle contrast:
#   K = sigma_I / <I>.
#
# Kevin van As
#	01 03 2019: Original
#	06 03 2019: Implemented grid
#	07 03 2019: Implemented sliding window
#				(Note: does not give significant different results than non-sliding for me: <1% difference)
#	19 07 2019: Added sanity checks to return NaN if window/grid is impossible for input datasize.
#

# Misc imports

# Numerics
import numpy as np # Matrices

# Import from optoFluids:
import helpers.printFuncs as myPrint
import helpers.strConversions as str2

def basic(data):
	return np.std(data) / np.mean(data)

class window:
	def __init__(self, blockSize=None, sliding=False):
		self.setBlockSize(blockSize)
		self.sliding = str(sliding).lower() in ['true', '1', 't', 'y', 'yes', 'sliding']

	def setBlockSize(self, blockSize):
		if (blockSize == None):
			self.blockSize=(8,8) # default value
			myPrint.Printer.vprint("in speckleContrast: did not specify blockSize, so using default: " + str(self.blockSize) + ".")
			return
		
		if (type(blockSize) == str):
			blockSize=str2.strToIntVec(blockSize)

		if (len(blockSize) != 2):
			raise Exception("ERROR in speckleContrast: Windowing requires a tuple of length two for blockSize, but received length "
					+ len(blockSize) + ": " + str(blockSize) + ".")
	
		if (type(blockSize[0]) == str):	
			blockSize=str2.strVecToIntVec(blockSize)

		if ( not blockSize[0] > 0 or not blockSize[1] > 0 ):
			raise Exception("ERROR in speckleContrast: Windowing requires blockSize=(int,int) with numbers>0, but received: \"" + str(blockSize) + "\".")

		# At this point, everything is OK!
		self.blockSize=blockSize

	def __call__(self,data):
		# Sanity check on data size:
		npix=np.shape(data)
		if blockSize[0]>npix[0] or blockSize[1]>npix[1]:
			# Window is larger than the entire camera! We cannot deal with this!
			return float('NaN')

		# Compute speckle contrast:
		if(self.sliding):
			return self.computeSliding(data)
		else:
			return self.computeStatic(data)

	def computeStatic(self,data):
		myPrint.Printer.vprint("Using static window speckle contrast calculation.")
		assert (len(np.shape(data)) == 2), "in speckleContrast: \"window\" only works with a 2D array"
		C = 0.
		n = 0
		# TODO: if len(data) not a multiple of blockSize, then a part of data will currently be ignored.
		#		Solutions: call the grid class with a float number of pixels; or use a sliding window.
		#		Not realy a solution: extend the last window (with if), as that might increase it by almost a factor two in size!
		for i in range(0, int( len(data[:, 0]) / self.blockSize[0] ) ):
			irange = ( (i * self.blockSize[0]), ((i+1) * self.blockSize[0]) )
			for j in range(0, int( len(data[0, :]) / self.blockSize[1] ) ):
				jrange = ( (j * self.blockSize[1]), ((j+1) * self.blockSize[1]) )
				dataLocal = data[	slice(*irange), slice(*jrange)	]
				Cnew = basic(dataLocal)
				C += Cnew
				n += 1
				# Info message:
				myPrint.Printer.vprint(str(irange) + " x " + str(jrange) +
					myPrint.addSpaces(":",
						30 - (len(str(irange)) + len(str(jrange)))
					) +
					"C=" + str(Cnew))
		return C / float(n)

	def computeSliding(self,data):
		myPrint.Printer.vprint("Using sliding window speckle contrast calculation.")
		assert (len(np.shape(data)) == 2), "in speckleContrast: \"window\" only works with a 2D array"
		C = 0.
		n = 0
		for i in range(
						int(np.ceil( (self.blockSize[0]-1)/2 )),
						len(data[:,0]) - int( (self.blockSize[0]+1)/2 ) # floor
					):
			irange = ( int(i - (self.blockSize[0]-1)/2), int(i + (self.blockSize[0]+1)/2) )
			for j in range(
							int(np.ceil( (self.blockSize[1]-1)/2 )),
							len(data[0,:]) - int( (self.blockSize[1]+1)/2 ) # floor
						):
				#print(str(i) + "," + str(j))
				jrange = ( int(j - (self.blockSize[1]-1)/2), int(j + (self.blockSize[1]+1)/2) )
				dataLocal = data[	slice(*irange), slice(*jrange)	]
				Cnew = basic(dataLocal)
				C += Cnew
				n += 1
				# Info message:
				myPrint.Printer.vprint(str(irange) + " x " + str(jrange) +
					myPrint.addSpaces(":",
						30 - (len(str(irange)) + len(str(jrange)))
					) +
					"C=" + str(Cnew))
		return C / float(n)

class grid:
	def __init__(self, gridSize=None):
		self.setGridSize(gridSize)

	def setGridSize(self, gridSize):
		if (gridSize == None):
			self.gridSize=(8,8) # default value
			myPrint.Printer.vprint("in speckleContrast: did not specify gridSize, so using default: " + str(self.gridSize) + ".")
			return
		
		if (type(gridSize) == str):
			gridSize=str2.strToIntVec(gridSize)

		if (len(gridSize) != 2):
			raise Exception("ERROR in speckleContrast: Using a grid requires a tuple of length two for gridSize, but received length "
					+ len(gridSize) + ": " + str(gridSize) + ".")
	
		if (type(gridSize[0]) == str):	
			gridSize=str2.strVecToIntVec(gridSize)

		if ( not gridSize[0] > 0 or not gridSize[1] > 0 ):
			raise Exception("ERROR in speckleContrast: Using a grid requires gridSize=(int,int) with numbers>0, but received: \"" + str(gridSize) + "\".")

		# At this point, everything is OK!
		self.gridSize=gridSize

	def __call__(self, data):
		assert (len(np.shape(data)) == 2), "in speckleContrast: \"grid\" only works with a 2D array"
		npix=np.shape(data)
		blockSize=(npix[0]/self.gridSize[0], npix[1]/self.gridSize[1])
		if blockSize[0]<1 or blockSize[1]<1:
			# Grid blocks smaller than one pixel! We cannot compute that!
			return float('NaN')
		C = 0.
		n = 0
		for i in range(0, self.gridSize[0]):
			irange = ( round(i * blockSize[0]), round((i+1) * blockSize[0]) )
			for j in range(0, self.gridSize[1]):
				jrange = ( round(j * blockSize[1]), round((j+1) * blockSize[1]) )
				# Compute:
				dataLocal = data[	slice(*irange), slice(*jrange)	] # Note to self: using "range" instead of "slice" only leaves the diagonal. (???)
				Cnew = basic(dataLocal)
				C += Cnew
				n += 1
				# Info message:
				myPrint.Printer.vprint(str(irange) + " x " + str(jrange) +
					myPrint.addSpaces(":",
						30 - (len(str(irange)) + len(str(jrange)))
					) +
					"C=" + str(Cnew))
		return C / float(n)

# EOF
