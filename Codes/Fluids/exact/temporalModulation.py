#! /usr/bin/env python3
#
# This module contains several temporal flow modulations, to-be-used by "moveParticles.py".
#  All callables only use time as input argument.
#  'lookupTable' requires construction before it may be used as a callable.
#
# Kevin van As
#	23 11 2018: Original
#	04 12 2018: Implemented lookupTable
#	05 02 2019: Implemented sine function

import os.path
import numpy as np
from io import StringIO

def none(t):
	return 1

class sin:
	# 'frequency' is the frequency [Hz] of the sine function, such that period=1/f and omega=2*pi*f.
	# 'amplitude' is the amplitude of the sine function (so peak-crest is 2*amplitude).
	# 'offset' shifts the sine vertically. WARNING: Then the sine will no longer have a mean of one.
	# 'phase' [deg] shifts the sine functions horizontally. If you want to shift in coordinate space, then use `t_min = phase/(2*pi*f)` to set the right phase.
	def __init__(self, frequency, amplitude, offset=0, phase=0):
		#print("frequency = " + str(frequency) + ", amplitude = " + str(amplitude) + ", offset = " + str(offset) + ", phase = " + str(phase) + ".")
		self.amp = float(amplitude)
		self.omega = 2*np.pi * float(frequency)
		#self.period = 1.0/frequency
		self.offset = float(offset)
		self.phase = float(phase)/180.0*np.pi # deg2rad phase
	def __call__(self, t):
		# A*sin(wt+phi)+1 has mean one.
		return np.sin(self.omega * t + self.phase)*self.amp + 1 + self.offset

class lookupTable:
	def __init__(self, table, boundaryStrategy="cyclic", scaleToMeanOne=True): #TODO: offset time;
		self.boundaryStrategy = boundaryStrategy
		self.scaleToMeanOne = bool(scaleToMeanOne)

		#print("table = " + str(table) + " is a " + str(type(table)))
		#print("boundaryStrategy = " + str(boundaryStrategy) + " is a " + str(type(boundaryStrategy)))

		# First check if table is a filename
		if ( table is None or table == "" ):
			raise ValueError("Received table=" + str(table) + ", but it cannot be None or \"\".")
		if ( os.path.exists(table) ): # Is "table" an existing filename?
			# read the file into an array:
			self.readTableFromFile(table)
		else: # Else just assume it is a data table. self.setTable will do all checks
			self.setTable(table)

		#print("self.table = " + str(self.table))

	def readTableFromFile(self, FN):
		# Sanity Check
		if ( not os.path.exists(FN) ):
			raise ValueError("File \"" + str(FN) + "\" does not exist.")
		# Read datafile
		dataFile = open(FN)
		dataStr = dataFile.read().replace("(", "").replace(")", "").strip()
		#dataStr = dataFile.read().strip()
		# skip_header to skip the first two lines of the input file, which are (line 1) the number of particles integer and (line 2) just an opening bracket
		self.setTable( np.genfromtxt(StringIO(dataStr), skip_header=0) ) # Gives 2D array. Each row has [time, value]
		dataFile.close()

	def setTable(self, table):
		## Check if ascending Nx2 matrix
		# Type OK?
		if not isinstance(table, np.ndarray):
			raise ValueError("Received table=\"" + str(table) + "\" of type \"" + str(type(table)) +
							", but required a 2D numpy.ndarray with on each row: [time,value].")
		# Shape OK?
		shape = np.shape(table)
		#print("shape = ", shape, len(shape))
		if not len(shape) == 2:
			raise ValueError("Received table=\"" + str(table) + "\" of type \"" + str(type(table)) + "\" with shape \""+str(shape)+
							"\", which is not a 2D dataset with per row: [time,value].")
		if not shape[1] == 2:
			raise ValueError("Received table=\"" + str(table) + "\" of type \"" + str(type(table)) + "\" with shape \""+str(shape)+
							"\", which does not have precisely two values per row: [time,value].")
		# Is ascending?
		#print(table[:,0])
		#print(		np.argmin(table[:,0]), np.argmax(table[:,0]) )
		if not np.argmin(table[:,0]) == 0:
			raise ValueError("Received table=\"" + str(table) + "\" of type \"" + str(type(table)) + "\" with shape \""+str(shape)+
							"\", with the correct format. However, the minimum time is not the first entry in the list, but was found at index " +
							str(np.argmin(table[:,0])) + ".")
		if not np.argmax(table[:,0]) == len(table[:,0])-1:
			raise ValueError("Received table=\"" + str(table) + "\" of type \"" + str(type(table)) + "\" with shape \""+str(shape)+
							"\", with the correct format. However, the maximum time is not the last entry in the list, but was found at index " +
							str(np.argmax(table[:,0])) + ".")

		# Scale to mean=1?
		if self.scaleToMeanOne:
			table[:,1] = table[:,1] / np.mean(table[:,1])

		## OK!
		self.table = table
		#print("Table = ", table)

	# Apply the boundaryStrategy to determine at what time the table should be read:
	# Clamp = min or max t of table
	# Cyclic = apply modulus to bound t to the table's range
	# Reverse = like cyclic, but reverse consecutive cycles
	def handleBoundary(self, t):
		tmin = self.table[0,0]
		tmax = self.table[-1,0]
		if self.boundaryStrategy=="clamp":
			return min(max(t,tmin),tmax)
		if self.boundaryStrategy=="cyclic":
			T = tmax-tmin
			return (t-tmin)%T+tmin
		if self.boundaryStrategy=="reverse":
			T = tmax-tmin
			numOff=int((t-tmin)/T)
			if t<tmin: numOff=numOff-1 # int(-0.1)=0, but I need it to be -1. Otherwise the "numOff" series is: (...,-1,0,0,1,2,3,...), which is no good: 0 repeats.
			#print("numOff=", numOff)
			if(numOff%2 == 0): #then cyclic
				#print("just cyclic")
				return (t-tmin)%T+tmin
			else: #then reverse
				#print("reverse cyclic")
				return tmax-(t-tmin)%T
		raise ValueError('[temporalModulation] "' + str(self.boundaryStrategy) + '" is not a valid boundaryStrategy.\n' + 
						'Valid strategies are: "clamp", "cyclic", "reverse".')

	def __call__(self, t):
		#t=1.34-1e-3-1e-4
		#print("called with t = " + str(t))
		#print("time1 = " + str(t))
		t = self.handleBoundary(t) # Apply boundaryStrategy to time to bound it within the table's range
		#print("time2 = " + str(t))
		# Find location in table that t may be interpolated from:
		ti = np.searchsorted(self.table[:,0],t) # Find first index >= t
		#print("t=" + str(t) + "--> ti=" +str(ti) + "--> t(ti)=" + str(self.table[ti,0]))
		# Interpolate between ti-1 and ti:
		if not ti == 0:
			f = (
					( t - self.table[ti-1,0] )
					/
					( self.table[ti,0] - self.table[ti-1,0] )
				)
			val = self.table[ti,1]*f + self.table[ti-1,1]*(1-f)
		else:
			val = self.table[0,1]
		return val



	

# EOF
