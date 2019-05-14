#! /usr/bin/env python3
#
# Compute and plot the FFT of the speckle contrast.
# The speckle contrast is read from a .csv file.
#
# Kevin van As
#	15 04 2019: Quick hack script to plot all columns of a semi-colon separated file	
#	17 04 2019: Added CLI 
#

import numpy as np
#import matplotlib
import matplotlib.pyplot as plt
plt.switch_backend('agg') # Then we do not need an X-server to plot.
plt.rc('text', usetex=True)
plt.rc('text.latex', preamble=r'\usepackage{amsmath}')

import optparse

# Import from optoFluids:
import helpers.IO as optoFluidsIO
import helpers.printFuncs as myPrint
import PostProcessing.fft as fft


##############
## SETTINGS ##
##############

#parser = optparse.OptionParser(usage=usageString)
parser = optparse.OptionParser()
(opt, args) = (None, None)
parser.add_option('-i', dest='inFNs', action='append', type=str,
					   help="Input files to iterate over.")
parser.add_option('-o', dest='outFN', type=str, default="./SCfft",
					   help="Prefix of the output filename (so without extention) [default: %default]")
parser.add_option("-v", action="store_true", dest="verbose", default=False,
					   help="verbose? [default: %default]")
parser.add_option('--mod', dest='tempMod', choices=['sin','Baker2017'],
					   help="temporal flow modulation: {sin, Baker2017}")
parser.add_option('--flow', dest='spatProf', choices=['plug','Pois'],
					   help="Spatial profile (used in figure title): {plug, Pois}.")
parser.add_option('--t0', dest='t0', type=float, default=-1e99,
					   help="Only calculate fft with time range: starting value.")
parser.add_option('--t1', dest='t1', type=float, default=1e99,
					   help="Only calculate fft with time range: ending value.")
parser.add_option('--f0', dest='f0', type=float, default=-1e99,
					   help="Plot frequency range: starting value.")
parser.add_option('--f1', dest='f1', type=float, default=1e99,
					   help="Plot frequency range: ending value.")
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
fontsize=25
numbersize=17

## Input files:
if opt.inFNs is None:
	inFNs=['./SC.csv']
else:
	inFNs=opt.inFNs
myPrint.Printer.vprint("Using input files: " + str(inFNs))
delim=';'
skip_header=1
## Compute: 		#TODO: CLI for zeroMean and operation.
zeroMean=True # Subtract mean of signal to cancel f=0 peak?
operation=np.abs
t_range=(opt.t0, opt.t1)
## Output:
outFN=opt.outFN
extention="png"
dpi=160
myPrint.Printer.vprint("Output location: " + str(outFN)+"_*."+str(extention))

## Vertical lines:
if opt.tempMod=="Baker2017": # Baker 2017 heartbeat signal
	signal_T=0.835
	peak_freq=[1.0/signal_T]
elif opt.tempMod=="sin": # Sinus
	signal_T=1.0
	peak_freq=[1.0/signal_T]
else: # else no vertical lines
	signal_T=1.0
	peak_freq=[]
## Frequency range to plot:
f_range=(opt.f0, opt.f1) # use this data
#f_axisrange=(0, np.ceil(20/signal_T/2) ) # scale axis to this; use None to turn off


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

tid_range=()
for item in t_range:
	tid_range = tid_range + ( np.searchsorted(data[:,0,0], item, side="left") , )
myPrint.Printer.vprint("Only calculating fft using time range: (" + str(data[tid_range[0],0,0]) + "," + str(data[tid_range[1]-1,0,0]) + ")")
tid_range=range(*tid_range)

myPrint.Printer.vprint("np.shape(input) = " + str(np.shape(data)))
f = fft.fftfreq(data[tid_range,0,0])
Y = fft.fft(data[tid_range,1:,0], zeroMean=zeroMean, scale2max1=True) # Skip first column (as that's t)
myPrint.Printer.vprint("np.shape(fftfreq) = " + str(np.shape(f)))
myPrint.Printer.vprint("np.shape(fft) = " + str(np.shape(Y)))

# Print fft array entirely:
#myPrint.Printer.vprint("abs(fft) = " + str(np.abs(Y).tolist()))
# Print fft array of grid16:
#myPrint.Printer.vprint("abs(fft) = " + str(np.abs(Y[:,3]).tolist()))

def is_in_range(num, rng):
	return (num <= rng[1]) and (num >= rng[0])
def add_xvline():
	plt.axvline(x=peak_freq, color='k', linestyle='--', linewidth=1)

##############
## Plotting ##
##############


#colors = ('kd-','ro-','b^-','g+-','mx-','ys-')
#colors = ('kd-','ko-','k^-','k+-','kx-','ks-')
#colors = ('kx-','rx-','bx-','gx-','mx-','yx-')

fid_range=()
for item in f_range:
	fid_range = fid_range + ( np.searchsorted(f, item, side="left") , )
fid_range=range(*fid_range)
myPrint.Printer.vprint("Only printing the frequency range: " + str(f_range) + " --> ids = " + str(fid_range))

for iC in range(1,len(data[0,:,0])): # Way of calculating the speckle contrast
	fig = plt.figure(dpi=dpi)
	# Use "iC-1" for Y, as we discarded the time column (so all columns shifted by 1 left):
#	plt.plot(data[fid_range,0,0], data[fid_range,iC,0], colors[iC-1], fillstyle='none')
	plt.plot(f[fid_range], operation(Y[fid_range,iC-1]), 'k-', fillstyle='none')
	if opt.tempMod=="Baker2017": plt.plot([12], [0], 'w', markersize=0) # Add an invisible point at end, such that auto scaling scales until 12 + margin
	plt.xlabel(r'$f$', fontsize=fontsize)
	plt.ylabel(r'$\left|\mathcal{F}\{C\}\right|$', fontsize=fontsize)
	plt.xticks(fontsize=numbersize)
	plt.yticks(fontsize=numbersize)
#	plt.legend(header[0][1:])
	if opt.title is None: # then use default title name
	#	title_settings="1.25e-2 20pT 1m/s 100us"
		title_suffix=" (" + str(opt.tempMod) + "\_" + str(opt.spatProf) + ")"# + " " + str(title_settings)
		title="Frequency spectrum for " + str(header[0][iC]) + " " + str(title_suffix)
	else: # otherwise use user title
		title=opt.title
	if not opt.noTitle:
		plt.title(title)
	#plt.xscale('log', basex=2)
	#plt.show()
#	add_xvline()
#	if f_axisrange is not None:
#		myPrint.Printer.vprint("f_axisrange = " + str(f_axisrange))
#		plt.xlim(f_axisrange)
	fig.savefig(outFN + "_" + str(header[0][iC]) + "." + extention, bbox_inches = "tight")



# EOF
