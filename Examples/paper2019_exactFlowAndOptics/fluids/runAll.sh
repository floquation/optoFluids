#! /usr/bin/env bash
# MUST BE RAN FROM THE SCRIPT'S DIRECTORY

mainDir=".."
source "$mainDir/input_names" || exit 1 # Source name conventions

fluidsInFN="./input_flow"
optoFluidsInFN="$mainDir/input_time"

ICfile="$(makeInitParticles.sh "$fluidsInFN")" || exit 1 # Generate IC
moveParticles.sh "$fluidsInFN" "$optoFluidsInFN" "$ICfile" "$mainDir/$particlesDN" "$@" || exit 1  # Evolve particles
