#! /usr/bin/env bash

base="."
if [ "$1" != "" ]; then
	base="$1"
fi

resultDN="results"
if [ "$2" != "" ]; then
        resultDN="$2"
fi

## Obtain multiple directories
# Get items in sorted order:
intensityFNs=( "$base/$resultDN/2D/blurred/"* ) # get result directories
idid="_t" # Thing that comes just before the identifier
i=0
unset ids prefixes
for item in ${intensityFNs[*]}
do
	ids[$i]=$(echo "$(basename "$item")" | sed -r 's/.*'"$idid"'//g') # extract numerical identifier
	prefixes[$i]=$(echo "$item" | sed -r 's/(.*'"$idid"').*/\1/g') # everything but the identifier
	i=$((i+1))
done
IFS=$'\n' ids=($(sort -g <<<"${ids[*]}")); unset IFS # sort
# Generate FNs in sorted order:
i=0
for id in ${ids[@]}
do
	intensityFNs[$i]="${prefixes[$i]}$id"
	i=$((i+1))
done

#echo "${ids[@]}"
#echo "${intensityFNs[@]}"

## Compute speckle contrast
#echo "t;basic;grid4;grid8;grid16"
echo "t;grid16"
i=0
for FN in ${intensityFNs[*]}
do
#	SC=$(computeSpeckleContrast.py -i $DN/2D/blurred/Intensity2D_t0.0 "$@")
	#SC[0]=$(computeSpeckleContrast.py -i $FN -t basic $@)
	#SC[1]=$(computeSpeckleContrast.py -i $FN -t grid --args "(4,4)" $@)
	#SC[2]=$(computeSpeckleContrast.py -i $FN -t grid --args "(8,8)" $@)
	SC[0]=$(computeSpeckleContrast.py -i $FN -t grid --args "(16,16)" $@)
	SCstr=$(echo "${SC[*]}" | sed -e 's/ /;/g')
	echo "${ids[$i]};$SCstr"
	i=$((i+1))	
done

