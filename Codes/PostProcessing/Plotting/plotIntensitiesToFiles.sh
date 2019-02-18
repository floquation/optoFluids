#! /usr/bin/env bash
#
# Kevin van As
#  17 12 2018: Quick hack script to loop over all intensity files and plot all the images 
#

if [ "$1" == "" ] || [ "$2" == "" ]; then
	echo "\$1 should be inputDN, \$2 should be outputDN. Aborting."
	exit 1
fi

inputDN="$1"
outputDN="$2"
shift 2; # Shift arguments to pass the remainder with $@ to the next script.

if [ -e "$outputDN" ]; then
	echo "Output directory '$outputDN' already exists. Aborting."
	exit 1
else
	mkdir "$outputDN"
fi
if [ ! -d "$inputDN" ]; then
	echo "Input directory '$inputDN' does not exist. Aborting."
	exit 1
fi

pixelCoordsFN="$inputDN/../PixelCoords2D.out" # Hacked location, valid for a sorted optoFluids case

num=1
maxNum=$(ls "$inputDN"/* | wc -l)
for inputFN in "$inputDN"/*
do
	echo "[$num/$maxNum]"
	outputFN="$outputDN/$(basename $inputFN)"
	#echo "outputFN = $outputFN"
	plotIntensityToFile.py -i "$inputFN" -o "$outputFN" -c "$pixelCoordsFN" $@ || exit 1
	num=$((num+1))
done






# EOF
