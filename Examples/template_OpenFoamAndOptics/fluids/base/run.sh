#! /usr/bin/env bash

#loadoptofluids
#of240
#./prepareCase.sh || exit 1
pimpleFoam > run.log || exit 1
