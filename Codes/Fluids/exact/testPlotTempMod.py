#! /usr/bin/env python3

# optoFluids:
import helpers.RTS as RTS
import temporalModulation

# Error handling:
import traceback

# Plotting:
import numpy as np
import matplotlib.pyplot as plt



if __name__ == '__main__':
	import optparse

	usageString = "usage: %prog -i <positionsfile> -o <outputfolder> [options]"

	# Init
	parser = optparse.OptionParser(usage=usageString)
	(opt, args) = (None, None)

	# Parse options
	parser.add_option('-o', dest='outputDN', default=".",
						   help="name of the output directory")
	parser.add_option('--mod', dest='tempMod', default="none",
						   help="temporal flow modulation, one of: " + str(RTS.getFunctions(temporalModulation)))
	parser.add_option('--t0', dest='t0', default="0",
						   help="Timestep for plotting")
	parser.add_option('--t1', dest='t1', default="1",
						   help="Timestep for plotting")
	parser.add_option('--dt', dest='dt', default="0.05",
						   help="Timestep for plotting")
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

	# Plot:	
	t = np.arange(float(opt.t0), float(opt.t1), float(opt.dt))
	y = np.zeros(len(t))
	for ti in range(len(t)):
		y[ti] = temporalModulation(t[ti])
	plt.plot(t, y, 'r--')
	plt.show()







# EOF