#! /bin/bash
# Take a particlePositions file as an argument ($1),
# which has one position per line in the format "(float,float,float)".
# This script adds the number of lines to the first line,
# "(" to the second line and ")" to the last line; as required by the optics code.
#
# Returns error 1 to stderr if the input file does not exist.
# If OK, outputs the new file to stdout.
#
# Usage:
# 	convertParticles2OptoFormat.sh particlePositionFileName > newFileName
#
# -- Kevin van As, 04/09/2018


partPosFile=$1

if [ ! -f "$partPosFile" ]; then
	>&2 echo "Input file \"$1\" does not exist."
	exit 1
fi

length=($(wc -l "$partPosFile"))
length=${length[0]}

echo "$length"
echo "("
cat "$partPosFile"
echo ")"

