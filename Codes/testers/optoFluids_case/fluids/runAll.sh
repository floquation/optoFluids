#! /usr/bin/env bash
# MUST BE RAN FROM THE SCRIPT'S DIRECTORY

mainDir=".."
source "$mainDir/input_names" || exit 1 # Source name conventions

fluidsInFN="./input_flow"
optoFluidsInFN="$mainDir/input_time"

ICfile="$(./makeInitParticles.sh "$fluidsInFN")" # Generate IC
./moveParticles.sh "$fluidsInFN" "$optoFluidsInFN" "$ICfile" "$mainDir/$particlesDN" "$@" # Evolve particles
rm "$ICfile" # No need to keep the IC file
