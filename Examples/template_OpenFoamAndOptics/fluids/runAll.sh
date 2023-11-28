#! /usr/bin/env bash

# Note: Uncomment the line you wish to run. Comment the other ones.
# Note: MUST be executed from script's directory!

# Serial Case:
./runFoam.sh ../input_time base

# Parallel Case (local machine):
#./runFoam.sh ../input_time base_parallel

# HPC Case:
#./makeJobFile.sh base
#./makeJobFile.sh base_parallel
#./makeJobFile.sh CarotidArtery_parallel
#./makeJobFile.sh CarotidArtery_serial
#qsub jobfile.pbs # Uncomment this if any of the three HPC cases are chosen

