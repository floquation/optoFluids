#! /usr/bin/env python3

# File system:
import os.path

# optoFluids:
import helpers.RTS as RTS
import temporalModulation

# Error handling:
import traceback

# Plotting:
import numpy as np
import matplotlib.pyplot as plt
#plt.switch_backend('agg') # Then we do not need an X-server to plot.
plt.rc('text', usetex=True)


def is_in_range(num, rng):
	return (num <= rng[1]) and (num >= rng[0])
def add_xvline(t_range, signal_T, signal_mins, signal_maxs, signal_toffset=0):
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


if __name__ == '__main__':
	import optparse

	usageString = "usage: %prog --mod temporalModulation-function"

	# Init
	parser = optparse.OptionParser(usage=usageString)
	(opt, args) = (None, None)

	# Parse options
	parser.add_option('-o', dest='outputFN',
						   help="name of the output file (excl. extension)")
	parser.add_option('--t0', dest='t0', default="0",
						   help="t_start")
	parser.add_option('--t1', dest='t1', default="1",
						   help="t_end")
	parser.add_option('--dt', dest='dt', default="0.05",
						   help="Timestep for plotting")
	parser.add_option('--mod', dest='tempMod', default="none",
						   help="temporal flow modulation, one of: " + str(RTS.getFunctions(temporalModulation)))
	parser.add_option('--modargs', dest='tempMod_args',
						   help="Required arguments for the temporal flow modulation (if any). Separate the parameters with a comma (e.g., --modargs \"a,b\").")
	parser.add_option("-v", action="store_true", dest="verbose", default=False,
						   help="verbose [default: %default]")
	parser.add_option("-f", action="store_true", dest="overwrite", default=False,
						   help="force overwrite output? [default: %default]")
	(opt, args) = parser.parse_args()

	(tempMod_args, tempMod_kwargs) = RTS.multiArgStringToArgs(opt.tempMod_args)

	try:
		temporalModulation = RTS.select(temporalModulation, str(opt.tempMod), *tempMod_args, **tempMod_kwargs)
	except:
		traceback.print_exc()

	# TODO: CL input
	dpi=160
	extention="png"
	if False:
		signal_T=0.835 # Baker 2017 heartbeat signal
		signal_mins=[0, 0.39] # Baker 2017 heartbeat signal
		signal_maxs=[0.115, 0.51] # Baker 2017 heartbeat signal
		title_suffix = ": heartbeat"
	else:
		signal_T=1
		signal_mins=[0.75]
		signal_maxs=[0.25]
		title_suffix = ": sinusoidal"

	# Sample data:	
	t = np.arange(float(opt.t0), float(opt.t1), float(opt.dt))
	y = np.zeros(len(t))
	for ti in range(len(t)):
		y[ti] = temporalModulation(t[ti])

	# Plot:
	fig = plt.figure(dpi=dpi)
	plt.plot(t, y, 'k-')
	plt.xlabel(r'$t$')
	plt.ylabel(r'$F(t)$')
	plt.title("Temporal modulation" + str(title_suffix))
	add_xvline((t[0],t[-1]),signal_T,signal_mins,signal_maxs)

	# Output:
	if opt.outputFN == None or opt.outputFN == "" or (os.path.exists(opt.outputFN) and (not opt.overwrite)):
		plt.show()
	else:
		fig.savefig(opt.outputFN + "." + extention)




# EOF
