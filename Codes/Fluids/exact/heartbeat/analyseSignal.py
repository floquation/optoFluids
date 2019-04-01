#! /usr/bin/env python3
#
# Quick hack-script to write the heartbeat function to a file
#  with optional rescaling (zeroMean, between 0 and 1).
# Heartbeat function has:
#  T  = 0.835s
#  dt = 0.005s
# 
# Jorne Boterman
#   01 01 2017:? Original in Matlab. Precise source unknown.
# Kevin van As
#	13 12 2018: Converted the Matlab-generator to a Python write2file script.
#


## HARD-CODED INPUT PARAMETERS start
FN="./heartbeatVelo_Baker2017" # Input FN.
## HARD-CODED INPUT PARAMETERS end

# IO:
import os.path
from io import StringIO

# Matrices:
import numpy as np

# Import from optoFluids:
import helpers.printFuncs as myPrint

def readTableFromFile(FN):
	# Sanity Check
	if ( not os.path.exists(FN) ):
		raise ValueError("File \"" + str(FN) + "\" does not exist.")
	# Read datafile
	dataFile = open(FN)
	dataStr = dataFile.read().replace("(", "").replace(")", "").strip()
	table = np.genfromtxt(StringIO(dataStr), skip_header=0) # Gives 2D array. Each row has [time, value]
	dataFile.close()
	return table

# Get data:
data = readTableFromFile(FN)
print("Data table (transposed):")
print(data)
print()
data = np.transpose(data)

# Signal length (duration)
T=data[0,-1]-data[0,0]
print("data len="+str(len(data[0,:]))+", duration="+str(T) + ", frequency=" + str(1.0/T) + ".")

# Max/min global:
print("data mean="+str(data[1,:].mean())+".")
argmin=np.argmin(data[1,:])
print("global min["+str(argmin)+"] = ["+str(data[0,argmin])+", "+str(data[1,argmin])+"].")
argmax=np.argmax(data[1,:])
print("global max["+str(argmax)+"] = ["+str(data[0,argmax])+", "+str(data[1,argmax])+"].")

# Max/min local:
def detectExtrema(data):
	extreme_is=[]

	last_val=data[0]
	if data[1] > last_val: # start with ascend, look for max.
		lookFor=1 # 1 = maxima; 0 = minima
	elif (data[1] < last_val): # start with descend, look for min.
		lookFor=0 # 1 = maxima; 0 = minima
	else: # start constant
		raise Exception("Not yet implemented: data starts with zero slope.")
	
	extreme_is.append((0,(lookFor+1)%2)) # First value is also an extrema (sort of)
	for i in range(1,len(data)):
		if data[i] < last_val:
			# next value is lower --> descend
			if lookFor==1: # so we have a maximum!
				extreme_is.append((i-1,lookFor))
				lookFor=0
		elif data[i] > last_val:
			# next value is higher --> ascend
			if lookFor==0: # so we have a minimum!
				extreme_is.append((i-1,lookFor))
				lookFor=1
		else:
			# saddle point, just keep looking for what we had already been looking for.
			# TODO (rare case): If the local max/min is a long zero-slope region, this will detect the last index of that region; not the mean.
			pass
		last_val=data[i]
	extreme_is.append((i,lookFor)) # Last value is also an extrema (sort of)
	return extreme_is
	
argextremes=detectExtrema(data[1,:])
#print(argextremes)
for argi in argextremes:
	if argi[1]==1:
		msg = "max"
	else:
		msg = "min"
	print("local "+msg+"["+str(argi[0])+"] = ["+str(data[0,argi[0]])+", "+str(data[1,argi[0]])+"].")






