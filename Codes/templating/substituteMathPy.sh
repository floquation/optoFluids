#! /usr/bin/env bash
#
# From a template file, substitute a mathematical expression using Python.
# The expression must be of the form "$mathPy expr$, for example:
# 	blabla $mathPy 4/2$ blabladiebla
# becomes:
# 	blabla 2.0 blabladiebla
# and
# 	blabla $mathPy int(4/2)$ blabladiebla
# becomes:
# 	blabla 2 blabladiebla
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
# 	substituteMathPy.sh inputFile [outputFile] [-f]
#
# Kevin van As
# 	25 02 2019: Original
#

# Args
inFN="$1" # input filename
outFN="$2" # [ output filename ]
if [ "$3" == "-f" ]; then
	overwrite=1
else
	overwrite=0
fi
shift 2

# Sanity
usage='Usage: substituteMathPy.sh inputFile [outputFile] [-f]'
if [ ! -f "$inFN" ]; then
	>&2 echo "\$1 should be the input file, but it is not a file: \"$inFN\"."
	>&2 echo "$usage"
	exit 1
fi
if [ -e "$outFN" ] && [ "$overwrite" == "0" ] ; then
	>&2 echo "\$2 is the output file, but it already exists: \"$outFN\", but \$3 was not \"-f\"."
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

# Do mathPy
grep -e "\$mathPy" "$outFN" | while read -r line ; do
	# Extract command:
	cmdRE='\$(mathPy .*)\$'
	cmdREext='.*'"$cmdRE"'.*'
	cmd=$(echo "$line"  | sed -r 's/'"$cmdREext"'/\1/g')
	xpr=$(echo "$cmd"  | sed -r 's/mathPy (.*)/\1/g')

	# Compute:
    res=$(python -c 'print('"$xpr"')')
	#res=$(mathPy '$xpr') # requires mathPy to be loaded, but it's just a one-liner, so don't use it.

	#echo $cmd
	#echo $xpr
	#echo $res
	#echo 's/'"$cmdRE"'/'"$res"'/'

	# Substitute the command for the result in the file:
	# (Only 1st occurrence sed, as the next occurrence is for the next while-iteration.)
	sed -i -r '0,/'"$cmdREext"'/{s/'"$cmdRE"'/'"$res"'/}' "$outFN"
done

