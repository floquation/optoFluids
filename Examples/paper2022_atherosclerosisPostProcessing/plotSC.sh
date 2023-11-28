#! /usr/bin/env bash

## Input:
verbose="-v"
title="--noTitle"

base="."
if [ "$1" != "" ]; then
	base="$1"
fi

suffix=""
if [ "$2" != "" ]; then
        suffix="$2"
fi

## Automatic input detection:
#source ../data_publication/input
sim_T=$(mathPy "1.34*35")

## Plot SC:
echo "/*************\\"
echo "| Plotting SC |"
echo "\\*************/"
plotSC_t.py -i "$base/SC$suffix".csv $title -o "$base/SC$suffix" --t1 "$sim_T" --y0 0.17 --y1 0.73 "$verbose"
#plotSC_t.py -i "$base/SC$suffix".csv $title -o "$base/SC$suffix" --t1 "$sim_T" "$verbose"
exit

## Plot fft{SC}:
echo "/**************\\"
echo "| Plotting fft |"
echo "\\**************/"
plotSC_fft.py -i "$base/SC$suffix".csv  $title -o "$base/SCfft$suffix" --t1 "$sim_T" "$verbose"
# KvA note: By including --t1, we will go UNTIL 40.0 (so excluding 40.0). That gives a better result than omitting it, as we do not want to include 40.0, as "40.0" is the same point as "0.0" and therefore the signal is not perfectly periodic if we include 40.0 as well as 0.0.
#plotSC_fft.py  $title -o "./SCfft_2p" --t1 $(mathPy "$sim_T/$num_cycles*2") "$verbose"
#plotSC_fft.py  $title -o "./SCfft_3p" --t1 $(mathPy "$sim_T/$num_cycles*3") "$verbose"
