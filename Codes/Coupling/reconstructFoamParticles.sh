#! /usr/bin/env bash
#
# Takes a decomposed openfoam case, and reconstructs only the particle positions,
# as those are all we need for the optics code.
#
# Kevin van As
#   02 10 2018: Original
# 

dirName=.
if [ ! "$1" == "" ]; then
    dirName="$1"
fi

if [ ! -d "$dirName" ]; then
    >&2 echo "'$dirName' does not exist."
    exit 1
fi

source "$OPTOFLUIDS_DIR/Codes/Fluids/foam_bash_functions" || exit 1
if [ $(isFoamCaseParallel $dirName) ]; then
    # Check if the case was already reconstructed entirely (#local time dirs = #processor time dirs)
    mydiff="$(diff <(getTimeDirs_serial "$dirName") <(getTimeDirs "$dirName") | wc -l)"
    if [ ! "$mydiff" == "0" ]; then
		# Extract particle positions:
		reconstructPar -lagrangianFields '(positions)' -fields '(none)' -noFunctionObjects -withZero -case "$dirName"
    else
		echo "'$dirName' was already reconstructed."
		echo "--> Skipping reconstruction."
		echo "Do you want to re-reconstruct the case? Then delete at least one reconstructed directory."
    fi
else
    echo "'$dirName' is not a parallel OpenFoam case."
    echo "--> Skipping reconstruction."
fi
