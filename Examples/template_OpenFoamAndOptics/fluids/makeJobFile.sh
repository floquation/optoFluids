#! /usr/bin/env bash
# $1 = OpenFOAM parallel case directory
# $2 = Optional overwrite for the HPC11 name that appears in the queue.

## Read input:
if [ "$1" == "" ]; then
    >&2 echo "\$1 should be the OpenFOAM parallel case directory."
    exit 1
fi
caseName="$1"
if [ ! -d "$caseName" ]; then
    >&2 echo "\"$caseName\" does not exist."
    exit 1
fi
runName="$(basename $caseName)"
if [ "$2" != "" ]; then
    runName="$2"
fi

## Extract number of processors from OpenFOAM case
nProc="$(cat "$caseName/system/decomposeParDict" | grep "numberOfSubdomains" | sed -e 's/^numberOfSubdomains\s\+//g' -e 's/;\s*//g')"

## Substitute results into jobfile.pbs
tmpVarFile=".kva_subst_jobfile"
echo "nProc=$nProc" > "$tmpVarFile"
echo "runName=$runName" >> "$tmpVarFile"
echo "caseName=$caseName" >> "$tmpVarFile"
templateSubstitutor.py -t "jobfile.pbs.tmplt" -v "$tmpVarFile" -o "jobfile.pbs" -f
rm "$tmpVarFile"



