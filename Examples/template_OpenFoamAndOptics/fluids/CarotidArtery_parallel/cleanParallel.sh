#! /usr/bin/env bash

curdir=$(pwd)
for dirs in $(find $curdir -mindepth 1 -maxdepth 1 -type d -name "processor*")
do
	echo 'Cleaning' "'$dirs'";
	cd $dirs;
	for subdirs in $(find $dirs -mindepth 1 -maxdepth 1 -type d -not -name "0" -not -name "constant")
	do		
		echo '   Removing' "'$subdirs'";
		'rm' -r $subdirs;
	done
	echo 'Done';
done

