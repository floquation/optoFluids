#! /usr/bin/env bash
#
# Note: Uncomment the line you wish to run. Comment the other ones.
# Line 14, 18, or 21 should be activated; the rest should be deactivated.
#
# Note: MUST be executed from script's directory!



## Run optics code

# Serial Case (local machine):
# (-C 1 is the default behaviour, so could be omitted.)
#timeLooperParallel.py -i particlePositions -o results -f -l -C 1

# Parallel Case (local machine):
# (-C 0 automatically detects the number of available system cores.)
#timeLooperParallel.py -i particlePositions -o results -f -l -C 0

# HPC Case:
qsub jobfile.pbs










# EOF
