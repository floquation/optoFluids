# !/usr/bin/env bash

date

## Fluids
cd fluids >/dev/null
./cleanAll.sh || exit 1
cd - >/dev/null

echo "####"
echo "##Fluids done."
date
echo "########"

## Optics
cd optics >/dev/null
./cleanAll.sh || exit 1
cd - >/dev/null

## Finish
date
