#! /usr/bin/env bash
#
# -- Kevin van As, 04/02/2019

# Preamble
scriptDir="$(dirname "$0")"
inputFluidFN="$1" # File that holds input parameters for the flow; to be sourced.
inputOptofluidFN="$2" # File that holds input parameters for what the optics code needs: camera integration time and related parameters; to be sourced.
partPosFN="$3" # Initial particle positions
outDN="$4" # Output directory name; sanity check is done by moveParticles.py
shift 4;

if [ -f "$inputFluidFN" ]; then
	source "$inputFluidFN"
else
	>&2 echo "Input file \"$inputFluidFN\" does not exist."
	exit
fi
if [ -f "$inputOptofluidFN" ]; then
	source "$inputOptofluidFN"
else
	>&2 echo "Input file \"$inputOptofluidFN\" does not exist."
	exit
fi
if [ ! -f "$partPosFN" ]; then
	>&2 echo "ParticlePositions file \"$partPosFN\" does not exist."
	exit
fi
if [ "$outDN" == "" ]; then
	outDN="particles"
fi

moveParticles.py -i "$partPosFN" -o "$outDN" \
	-u "$Umean" --flow="$profile" \
	--mod="$modulation" \
	--modargs "$modargs" \
	-L "$cyl_L" -R "$cyl_R" \
	-T "$sim_T" -n "$sim_n_T" \
	--t_int="$cam_t_int" --n_int="$cam_n_int" \
	--dt="$dt" \
	"$@"
	#-T $(mathPy "480e-6*20") -n $(mathPy "24*20")
