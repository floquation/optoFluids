#! /usr/bin/env bash
#
# From a template file, substitute a name by a value.
# The expression must be of the form "$name$, for example:
# 	blabla $name$ blabladiebla
# becomes:
# 	blabla value blabladiebla
#
# Great in combination with substituteParameter.sh to substitute a parameter,
# and then apply math to it, for example:
# 	inputOpticsIn="inputOptics.tmplt"
# 	ext="_$npix"
# 	inputOptics="$inputOpticsIn$ext"
# 	substituteParameter.sh "npix" "$npix" "$inputOpticsIn" "$inputOptics" -f || exit 1
# 	substituteMathPy.sh "$inputOptics" || exit 1
# Then this:
# 	blabla $mathPy int($npix$/2)$ blabladiebla
# becomes (with npix=256):
# 	blabla 128 blabladiebla
#
# Usage:
#	substituteParameter.sh parameter_name parameter_value inputFile [outputFile] [-f]
#
# Kevin van As
#	25 02 2019: Original
#

# Args
pName="$1" # parameter name
pVal="$2" # parameter value
inFN="$3" # input filename
outFN="$4" # [ output filename ]
if [ "$5" == "-f" ]; then
	overwrite=1
else
	overwrite=0
fi
shift 4

# Sanity
usage='Usage: substituteParameter.sh name value inputFile [outputFile] [-f]'
if [ "$pName" == "" ]; then
	>&2 echo "\$1 should be the parameter name, but received \"\"."
	>&2 echo "$usage"
	exit 1
fi
if [ "$pVal" == "" ]; then
	>&2 echo "\$2 should be the parameter value, but received \"\"."
	>&2 echo "$usage"
	exit 1
fi
if [ ! -f "$inFN" ]; then
	>&2 echo "\$3 should be the input file, but it is not a file: \"$inFN\"."
	>&2 echo "$usage"
	exit 1
fi
if [ -e "$outFN" ] && [ "$overwrite" == "0" ] ; then
	>&2 echo "\$4 is the output file, but it already exists: \"$inFN\", but \$5 was not \"-f\"."
	>&2 echo "$usage"
	exit 1
fi

# Create outputfile
if [ "$outFN" == "" ]; then
	# Output = Input:
	outFN="$inFN"
else
	# Create output file:
	rm -rf "$outFN" # overwrite was already checked above
	cp "$inFN" "$outFN"
fi

# Make the substitution
sed -i -r 's/\$'"$pName"'\$/'"$pVal"'/g' "$outFN"

