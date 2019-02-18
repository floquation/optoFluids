#! /usr/bin/env bash
# MUST BE RAN FROM THE SCRIPT'S DIRECTORY

mainDir=".."
source "$mainDir/input_names" || exit 1 # Source name conventions

NO_OF_CORES="$(cat "$PBS_NODEFILE" | wc -l)" || NO_OF_CORES=1

resultsDN="$mainDir/$opticsResultsDN"
timeLooperParallel.py -i "$mainDir/$particlesDN" -o "$resultsDN" -C "$NO_OF_CORES" "$@" || exit 1
./postProcessAll.sh "$resultsDN" || exit 1
