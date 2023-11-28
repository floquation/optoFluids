#! /usr/bin/env bash
# MUST BE RAN FROM THE SCRIPT'S DIRECTORY

mainDir=".."
source "$mainDir/input_names" || exit 1 # Source name conventions

NO_OF_CORES="$(cat "$PBS_NODEFILE" 2>/dev/null | wc -l)"; [ "$NO_OF_CORES" == 0 ] && NO_OF_CORES=1

inputOpticsIn="inputOptics.tmplt"

# Sanity:
resultsDN="$mainDir/$opticsResultsDN"
if [ -d "$resultsDN" ]; then
	>&2 echo "Skipping: $resultsDN (already exists)."
	exit 1
fi

# Substitute variable parameters:
#substituteParameter.sh "npix" "$npix" "$inputOpticsIn" "$inputOptics" -f || exit 1
inputOptics="$( echo "$inputOpticsIn" | sed -r 's/\.tmplt//g')"
substituteMathPy.sh "$inputOpticsIn" "$inputOptics" -f || exit 1

# Compute:
timeLooperParallel.py -i "$mainDir/$particlesDN" -o "$resultsDN" -C "$NO_OF_CORES" -t "$inputOptics" "$@" || exit 1
processOpticsOutput.sh "$resultsDN" || exit 1

# Post-process:
./computeSC.sh > SC.csv && ./plotSC.py || exit 1
#plotAll.sh || exit 1
