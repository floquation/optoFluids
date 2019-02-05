#! /usr/bin/env bash

from="$1"
to="$2"
cloud="particles"
if [ ! -d "$from" ]; then
    >&2 echo "'$from' is not an openfoam directory."
    exit 1
fi
if [ "$to" = "" ]; then
    >&2 echo "'\$2'='$to' cannot be null."
    exit 1
fi
if [ ! "$3" == "" ]; then
    cloud="$3"
fi

reconstructFoamParticles.sh "$from" || exit 1
convertFoam2OpticsParticlesSerial.py -i "$from" -c "$cloud" -o "$to" || exit 1

