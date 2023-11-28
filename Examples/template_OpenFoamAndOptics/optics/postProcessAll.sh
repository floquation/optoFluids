#! /usr/bin/env bash
#
# This script calls all post processing utilities for illustration purposes.
#
# -- Kevin van As, 11/10/2018

resultsDN="$1"
if [ "$resultsDN" == "" ]; then
	echo "\$1 should be the results directory"
	exit 1
fi


## Pre-postprocess the optics results:
# (1) Convert output to 2D format:
convertDataTo2D.py -i "$resultsDN" || exit 1
#convertDataTo2D.py -i results [-o results2D] [-f] [-C 0] || exit 1

onlyMajorSteps="False"
if [ "$onlyMajorSteps" == "False" ]; then
	# (2) Sort output by major/micro steps:
	# (Only execute this script for a case which has microsteps!
	#  Otherwise it will mistake the major steps to be microsteps!)
	sortOpticsResults.py -i "$resultsDN" || exit 1
	#sortOpticsResults.py -i results [-o results_sorted] [-p] [-f] [--tol 1.5] || exit 1
	
	# (3) Apply camera integration:
	# (Only execute this script for a case which has microsteps!
	#  Otherwise it will mistake the major steps to be microsteps!)
	timeIntegrateOptics_timeLooper.py -i "$resultsDN" || exit 1
	#timeIntegrateOptics_timeLooper.py -i "$resultsDN" [-o results_blurred] [-f] || exit 1

fi


## Post-process data:
# (1) Compute speckle contrast
# TODO: Looper version, on blurred directory
# computeSpeckleContrast.py -i results/2D/blurred/Intensity2D_t0.05 -x 1

# (2) Plot
# TODO

# (3)
# TODO



