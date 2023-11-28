#! /usr/bin/sh
#
# This script removes all directories relative to this script, while retaining all files.
# Unless you change this template's structure, this should perfectly clean the template.
#
# Kevin van As
#  December 2nd 2015


# Get the script's dir
current_dir=$(pwd)
script_dir=$(dirname $0)

if [ $script_dir = '.' ]
then
script_dir="$current_dir"
fi

#echo $script_dir

for f in $script_dir/*
do
    if [ -d $f ]; then
        echo "removed dir: $f"
        rm -r $f
    elif [ -f $f ]; then
        echo "retained file: $f"
    fi
done

