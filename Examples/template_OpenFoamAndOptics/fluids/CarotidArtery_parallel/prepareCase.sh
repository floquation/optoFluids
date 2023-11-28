#! /usr/bin/env bash

# MUST BE EXECUTED FROM THE SCRIPT'S DIR

# Make 0 directory:
cp -r 0.tmplt 0

# Decompose parallel case:
if [[ ! $(find . -type d -name 'processor*') == '' ]]; then echo 'removing old processor folders'; 'rm' -rf processor*; fi
decomposePar
