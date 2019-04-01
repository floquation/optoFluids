#! /usr/bin/env bash
#
# This script converts the output of the optics (Mie) code to a nice sorted directory:
#  Convert intensity files to 2D format
#  Sort files by major timestep
#  Integrated (blurred) over microsteps
#
# Kevin van As
#	11 10 2018: Original
#	07 02 2019: Improved comments
#				onlyMajorSteps command-line option
#

resultsDN="$1"; shift
if [ "$resultsDN" == "" ]; then
	echo "\$1 should be the results directory"
	exit 1
fi
onlyMajorSteps="False" # Cannot do camera integration steps if we only have major timesteps. This cannot be detected automatically (as the time structure is identical to not having microsteps instead), hence we need this flag.
if [ "$1" == "--onlyMajorSteps" ]; then
	shift
	onlyMajorSteps="True"
fi

echo "Converting $resultsDN to 2D"
## Pre-postprocess the optics results:
# (1) Convert output to 2D format:
convertDataTo2D.py -i "$resultsDN" -f || exit 1
#convertDataTo2D.py -i results [-o results2D] [-f] [-C 0] || exit 1

if [ "$onlyMajorSteps" == "False" ]; then
	# Only execute these script for a case which has microsteps!
	#  Otherwise it will mistake the major steps to be microsteps!
	#  That's why this is inside the onlyMajorSteps if-function.
	#
	# (2) Sort output by major/micro steps:
	echo "Sorting directory $resultsDN"
	sortOpticsResults.py -i "$resultsDN" -f || exit 1
	#sortOpticsResults.py -i results [-o results_sorted] [-p] [-f] || exit 1
#	echo "Time-integrating $resultsDN"
	# (3) Apply camera integration:
	timeIntegrateOptics_timeLooper.py -i "$resultsDN" || exit 1
fi


# EOF
