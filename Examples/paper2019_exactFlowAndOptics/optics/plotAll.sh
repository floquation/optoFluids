#! /usr/bin/env bash

plotDN=".plots"
plotSortDN="plots"

# Sanity
if [ -e "$plotSortDN" ]; then
	echo "Output directory \"$plotSortDN\" already exists. Terminating."
	exit 1
fi
[ -e "$plotDN" ] && rm -rf "$plotDN" # Overwrite tmp directory
mkdir $plotDN # Create tmp diretory

# Plotting
for resultsDN in results*
do
	id=$(echo "$resultsDN" | sed -e 's/results//g')
	plotIntensityToFile.py -i $resultsDN/2D/blurred/Intensity2D_t0.0 -o "$plotDN/plot$id"
done

# Sort
sortFrames.py -i $plotDN -o $plotSortDN -p "_" # Created sorted directory

# Clean-up
rm -rf "$plotDN" # Remove tmp directory
