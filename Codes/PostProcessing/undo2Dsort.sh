#! /usr/bin/env bash
#
# Undo the sorting of the optics directory into "1D", "2D" and "log" by
#  removing "2D",
#  putting the contents of "1D" back into the main directory,
#  leave "log" as-is.
#
# Kevin van As
#	12 10 2019: Original
#
# TODO: If 1D does not exist, but 2D does exist, then execute convertDataTo1D.py (or something).
# 		That script does not yet exist, but would do the opposite of convertDataTo2D.py
#		That way, we can get rid of the 1D directory everywhere: saves system space.
#		Not a high priority, though.
#

DN=$1

if [ "$DN" == "" ]; then
	(>&2 echo "\$1 should be the optics output directory name (with the 1D and 2D directories inside of it).")
	exit 1
fi

if ! [ -d "$DN"/1D ]; then
	(>&2 echo "\"$DN/1D\" does not exist. Cannot unsort this directory.")
	exit 1
fi

mv "$DN"/1D/* "$DN" && 'rm' -rf "$DN"/1D || exit 1
if [ -d "$DN"/2D ]; then
	'rm' -rf "$DN"/2D
fi
#if [ -d "$DN"/logs ]; then
#	mv "$DN"/logs/* "$DN" && 'rm' -rf "$DN"/logs
#fi
