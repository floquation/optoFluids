#! /usr/bin/env python3
#
# Plot the speckle contrast as read from a .csv file.
#
# Kevin van As
#	01 01 2019: Quick hack script to plot all columns of a semi-colon separated file	
#	17 04 2019: Added CLI 
#

import numpy as np
#import matplotlib
import matplotlib.pyplot as plt
plt.switch_backend('agg') # Then we do not need an X-server to plot.
plt.rc('text', usetex=True)

import optparse

# Import from optoFluids:
import helpers.IO as optoFluidsIO
import helpers.printFuncs as myPrint


##############
## SETTINGS ##
##############

#parser = optparse.OptionParser(usage=usageString)
parser = optparse.OptionParser()
(opt, args) = (None, None)
parser.add_option('-i', dest='inFNs', action='append', type=str,
					   help="Input files to iterate over.")
parser.add_option('-o', dest='outFN', type=str, default="./SC",
					   help="Prefix of the output filename (so without extention) [default: %default]")
parser.add_option("-v", action="store_true", dest="verbose", default=False,
					   help="verbose? [default: %default]")
parser.add_option('--mod', dest='tempMod', choices=['sin','Baker2017'],
					   help="temporal flow modulation: {sin, Baker2017}")
parser.add_option('--flow', dest='spatProf', choices=['plug','Pois'],
					   help="Spatial profile (used in figure title): {plug, Pois}.")
parser.add_option('--t0', dest='t0', type=float, default=-1e99,
					   help="Plot time range: starting value.")
parser.add_option('--t1', dest='t1', type=float, default=1e99,
					   help="Plot time range: ending value.")
parser.add_option('--y0', dest='y0', type=float, default=None,
					   help="Vertical axis: lower limit.")
parser.add_option('--y1', dest='y1', type=float, default=None,
					   help="Vertical axis: lower limit.")
parser.add_option('--title', dest='title', type=str,
					   help="Overwrite default title name with this string.")
parser.add_option("--noTitle", action="store_true", dest="noTitle", default=False,
					   help="Turn off title.")
(opt, args) = parser.parse_args()
myPrint.Printer.verbose = opt.verbose

# Use bold face everywhere:
if True:
	plt.rc('font', weight='bold') # every font bold (by default)
	plt.rcParams['text.latex.preamble'] = [r'\usepackage{bm}', r'\boldmath'] # bold LaTeX math mode
# Set font sizes:
fontsize=41
numbersize=2*17

## Input files
if opt.inFNs is None:
	inFNs=['./SC.csv']
else:
	inFNs=opt.inFNs
myPrint.Printer.vprint("Using input files: " + str(inFNs))
delim=';'
skip_header=1
## Output:
outFN=opt.outFN
extention="png"
dpi=160
myPrint.Printer.vprint("Output location: " + str(outFN)+"_*."+str(extention))

## Plot range:
t_range=(opt.t0, opt.t1)
## Vertical lines:
if opt.tempMod=="Baker2017": # Baker 2017 heartbeat signal
	signal_toffset=0
	signal_T=0.835
	signal_maxs=[0.115, 0.51]
	signal_mins=[0, 0.39]
elif opt.tempMod=="sin": # Sinus
	signal_toffset=0
	signal_T=1.0
	signal_maxs=[0.25]
	signal_mins=[0.75]
else: # else no vertical lines
	signal_toffset=0
	signal_T=1.0
	signal_maxs=[]
	signal_mins=[]

########
## IO ##
########

(data, header) = optoFluidsIO.readCSVs(inFNs, delimiter=delim, skip_header=skip_header)
# first index = row (~time)
# second index = column (~dataset)
# third index = different file (~file) --> Use [0] if only a single file.

###############
## Computing ##
###############

def is_in_range(num, rng):
	return (num <= rng[1]) and (num >= rng[0])
def add_xvline(t_range):
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
				plt.axvline(x=xplot,color='r',linestyle='-.') # minimum velocity
			#else:
				#print("out of range: xplot="+str(xplot))
		x += signal_T

##############
## Plotting ##
##############


#colors = ('kd-','ro-','b^-','g+-','mx-','ys-')
#colors = ('kd-','ko-','k^-','k+-','kx-','ks-')
#colors = ('kx-','rx-','bx-','gx-','mx-','yx-')

tid_range=()
for item in t_range:
	tid_range = tid_range + ( np.searchsorted(data[:,0,0], item, side="left") , )
tid_range=range(*tid_range)

for iC in range(1,len(data[0,:,0])): # Way of calculating the speckle contrast: columns of the datafile
	fig = plt.figure(dpi=dpi)
#	plt.plot(data[tid_range,0,0], data[tid_range,iC,0], colors[iC-1], fillstyle='none')
	plt.plot(data[tid_range,0,0], data[tid_range,iC,0], 'k-', fillstyle='none', markersize=5)
#	plt.plot(data[tid_range,0,1], data[tid_range,iC,1], 'go-', fillstyle='none')
	plt.xlabel(r'$'+str(header[0][0])+'$ [s]', fontsize=fontsize)
	plt.ylabel(r'$K$', fontsize=fontsize)
	plt.xticks(fontsize=numbersize)
	plt.yticks(fontsize=numbersize)
#	plt.legend(header[0][1:])
	if opt.title is None: # then use default title name
	#	title_settings="1.25e-2 20pT 1m/s 100us"
		title_suffix=" (" + str(opt.tempMod) + "\_" + str(opt.spatProf) + ")"# + " " + str(title_settings)
		title="Speckle contrast for " + str(header[0][iC]) + " " + str(title_suffix)
	else: # otherwise use user title
		title=opt.title
	if not opt.noTitle:
		plt.title(title)
	#plt.xscale('log', basex=2)
	#plt.show()
	add_xvline( ( max(t_range[0],data[0,0,0]) , min(t_range[1],data[-1,0,0])) ) # Added vertical lines within data range
	plt.ylim([opt.y0,opt.y1])
	fig.savefig(outFN + "_" + str(header[0][iC]) + "." + extention, bbox_inches = "tight")
	fig.savefig(outFN + "_" + str(header[0][iC]) + ".eps", format='eps', bbox_inches = "tight")



# EOF
