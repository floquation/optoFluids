#! /usr/bin/env python3
#
# Quick hack script to plot all columns of a semi-colon separated file

import numpy as np
#import matplotlib
import matplotlib.pyplot as plt
plt.switch_backend('agg') # Then we do not need an X-server to plot.
plt.rc('text', usetex=True)


##############
## SETTINGS ##
##############

dpi=160
inFNs=('./SC.csv',)
t_range=(0, 5)
#signal_T=0.835 # Baker 2017 heartbeat signal
signal_T=1.0 # Sinus
signal_toffset=0
#signal_maxs=[0.115, 0.51] # Baker 2017 heartbeat signal
#signal_mins=[0, 0.39] # Baker 2017 heartbeat signal
signal_maxs=[0.25] # Sinus 
signal_mins=[0.75] # Sinus 
title_suffix=" (sinus\_plug) 1.25e-2 20pT 1m/s 100us"
#nints=[10,20,40,80,160]
delim=';'
skip_header=1
outFN="./SC"
extention="png"

########
## IO ##
########

data=() # Read multiple data sets into a list (n-tuple)
header=()
for i, inFN in enumerate(inFNs):
	data = data + (np.genfromtxt(inFN, delimiter=delim, dtype=float, skip_header=skip_header),)
	header = header + (np.genfromtxt(inFN, delimiter=delim, dtype=str, skip_footer=len(data[i])),)

#print(data)
#print(np.shape(data))
data = np.dstack(data) # Convert list of 2D arrays to a 3D array
#print(data)
#print(np.shape(data))
#print(header)


###############
## Computing ##
###############

##############
## Plotting ##
##############

def is_in_range(num, rng):
	return (num <= rng[1]) and (num >= rng[0])
def add_xvline():
	x = signal_toffset
	# Find first required line:
	while x<t_range[0]:
		x += signal_T
	x -= signal_T
	# Make lines, repeating until the end of the time range
	while x-signal_T<t_range[1]:
		#print("x="+ str(x))
		for maxt in signal_maxs:
			xplot = x + maxt
			if is_in_range(xplot,t_range):
				plt.axvline(x=xplot,color='g',linestyle='--') # maximum velocity
			#else:
				#print("out of range: xplot="+str(xplot))
		for mint in signal_mins:
			xplot = x + mint
			if is_in_range(xplot,t_range):
				plt.axvline(x=xplot,color='r',linestyle='--') # minimum velocity
			#else:
				#print("out of range: xplot="+str(xplot))
		x += signal_T


#colors = ('kd-','ro-','b^-','g+-','mx-','ys-')
#colors = ('kd-','ko-','k^-','k+-','kx-','ks-')
#colors = ('kx-','rx-','bx-','gx-','mx-','yx-')

tid_range=()
for item in t_range:
	tid_range = tid_range + ( np.searchsorted(data[:,0,0], item, side="left") , )
tid_range=range(*tid_range)

for iC in range(1,len(data[0,:,0])): # Way of calculating the speckle contrast
	fig = plt.figure(dpi=dpi)
#	plt.plot(data[tid_range,0,0], data[tid_range,iC,0], colors[iC-1], fillstyle='none')
	plt.plot(data[tid_range,0,0], data[tid_range,iC,0], 'ko-', fillstyle='none')
	plt.xlabel(r'$'+str(header[0][0])+'$')
	plt.ylabel(r'$C$')
#	plt.legend(header[0][1:])
	plt.title("Speckle contrast for " + str(header[0][iC]) + " " + str(title_suffix))
	#plt.xscale('log', basex=2)
	#plt.show()
	add_xvline()
	fig.savefig(outFN + "_" + str(header[0][iC]) + "." + extention)



# EOF
