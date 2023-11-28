#! /usr/bin/env bash
# Must execute from script's directory

date >> run.log
nProc="$(cat ./system/decomposeParDict | grep "numberOfSubdomains" | sed -e 's/^numberOfSubdomains\s\+//g' -e 's/;\s*//g')"
mpirun -np "$nProc" -bind-to core -bycore pimpleFoam -parallel >> run.log || exit 1
date >> run.log
