#! /usr/bin/env sh
#
# Quick script that calls genCylParticles.py and convertParticles2OptoFormat.sh.
# Usage:
#  fluidsInFN="./input_flow" # Parameter file to-be-sourced
#  ICfile="$(./makeInitParticles.sh "$fluidsInFN")" # Generate IC 
#  Optional: $2 is the output filename (defaults to "pos_t0").
#
# -- Kevin van As, 04/02/2019

# Preamble
#scriptDir="$(dirname "$0")"
inputFileName="$1"
if [ "$2" == "" ]; then # Use $2 to overwrite the default particlePositionsFileName
	partPosFN="pos_t0"
else
	partPosFN="$2"
fi

if [ -f "$inputFileName" ]; then
	source "$inputFileName"
else
	>&2 echo "Input file \"$1\" does not exist."
	exit
fi

# Generate particle positions
if [ "$geom" = "cyl" ]; then
	AartsFN="$(dirname $(which genCylParticles.py))/AartsFig4_probAccum.dat"
	genCylParticles.py \
		-i "$AartsFN" \
		-R "$cyl_R" \
		-L "$cyl_L" \
		-O "$geom_origin" \
		-N "$N" \
		-o "$partPosFN" \
		-f || exit 1
else
	>&2 echo "\$geom=\"$geom\" is not supported."
	exit 1
fi

# Convert file format
convertParticles2OptoFormat.sh "$partPosFN" > "$partPosFN.tmp"
mv "$partPosFN.tmp" "$partPosFN"

echo "$partPosFN"
