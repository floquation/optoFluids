#! /usr/bin/env bash
#
# Copies an existing (executed) optoFluids case, without copying the generated results.
#
# Kevin van As
#  03 04 2019: Original
#

## Input

case1="$1"
case2="$2"

## Sanity Checks

if [ "$case1" == "" ]; then
	>&2 echo "\$1 must be the case to-be-copied (source)."
	exit 1
fi
if [ "$case2" == "" ]; then
	>&2 echo "\$2 must be the new (target) directory."
	exit 1
fi

if [ -e "$case2" ]; then
	>&2 echo "Output directory \"$case2\" already exists. Aborting."
	exit 1
fi

## All OK

duplicateFluids() {
	fluidsDN="$case2/fluids"
	mkdir "$fluidsDN"
	for item in "$1"/*
	do
		# Don't copy particles:
		if [ "$(echo "$(basename "$item")" | grep -e "^pos_t")" != "" ]; then
			continue
		fi
		if [ "$(echo "$(basename "$item")" | grep -e "^particle")" != "" ]; then
			continue
		fi
		# Else copy:
		cp -r "$item" "$fluidsDN"
	done
}
duplicateOptics() {
	opticsDN="$case2/optics"
	mkdir "$opticsDN"
	for item in "$1"/*
	do
		# Don't copy results:
		if [ "$(echo "$(basename "$item")" | grep -e "^results")" != "" ]; then
			continue
		fi
		if [ "$(echo "$(basename "$item")" | grep -e "\.png$")" != "" ]; then
			continue
		fi
		if [ "$(echo "$(basename "$item")" | grep -e "\.csv$")" != "" ]; then
			continue
		fi
		# Else copy:
		cp -r "$item" "$opticsDN"
	done
}

mkdir "$case2"
for item in "$case1"/*
do
	# Skip hpc output/error files:
	if [ "$(echo "$item" | grep -e "\.[oe][0-9]\+$")" != "" ]; then
		continue
	fi
	# Treat directories differently:
	if [ "$(basename "$item")" == "fluids" ]; then
		duplicateFluids "$item"
		continue
	fi
	if [ "$(basename "$item")" == "optics" ]; then
		duplicateOptics "$item"
		continue
	fi
	if [ -d "$item" ]; then
		echo "WARNING: \"$item\" is a directory, but not expected. Skipping the copy!"
		continue
	fi
	# Else copy:
	cp -r "$item" "$case2"
done





