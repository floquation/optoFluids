#! /usr/bin/env bash

case_base="base" # base casename default value, overwrite using $2.

#################
## (0) Initialisation & Sanity checks
#####

# Read command-line
[ "$1" == "" ] && >&2 echo "Must specify the optoFluids input file as \$1." && exit 1
optoFluids_input="$1"
[ ! "$2" == "" ] && case_base="$2"

# Define other cases
case_ICgen="$case_base"_ICgen # generate IC case
case_run="$case_base"_run # large write interval case
case_us="$case_base"_us # microstepping case; note: may be the same directory as $case_run
control_input=".control_input" # FN for the input to controlDict. N.B.: Relative path: stored in each case directory.

## Declare functions
# Does nothing:
doNothing(){
	echo "" > /dev/null
}
# Is this case parallel?
isFoamCaseParallel() {
	dirName="."
	[ "$1" != "" ] && dirName="$1"
	if [ -d "$dirName/processor0" ]; then
		# Assume this is a decomposed case if "processor0" exists.
		echo "true"
	fi
	# else echo "", which is the bash-equivalent of "false"
}
# Obtain a list of all time directories
# Including: exponential notation & decomposed cases
getTimeDirs() {
	dirName="."
	[ "$1" != "" ] && dirName="$1"
	# Obtain all times
	if [ $(isFoamCaseParallel $dirName) ]; then
		dirName="$dirName/processor0"
	fi
	timeDirs=(`ls "$dirName" | grep -E "^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$"`)
	[ "${#timeDirs[@]}" == 0 ] && ( >&2 echo "No timedirs found." ) && return 1
	# Sort times, including exponential notation
	IFS=$'\n' sorted=($(sort -g <<<"${timeDirs[*]}"))
	unset IFS
	## Return sorted time array
	echo "${sorted[@]}"
}
# Obtain the name of the last time directory of an OpenFOAM case.
# Including: exponential notation & decomposed cases
getLatestTime() {
	timeDirs=($(getTimeDirs $@))
	# Sort times in reverse, taking exponential notation into account
	IFS=$'\n' sorted=($(sort --reverse -g <<<"${timeDirs[*]}"))
	unset IFS
	# Show latest time
	echo "${sorted[0]}"
}

#[ $(isFoamCaseParallel base) ] && echo "true" || echo "false"
#[ $(isFoamCaseParallel base_parallel) ] && echo "true" || echo "false"
#exit 1

#timeDirs=$(getTimeDirs "$case_run")
#echo "${timeDirs[@]]}"
#echo $(getLatestTime "$case_run")
#exit

# Sanity checks
[ ! -d "$case_base" ] && >&2 echo "Input directory \"$case_base\" does not exist."  && exit 1
[ ! -d "$case_base/system" ] && >&2 echo "Input is not an OpenFOAM case directory! Expected \"$case_base/system\" to exist."  && exit 1
[ ! -d "$case_base/constant" ] && >&2 echo "Input is not an OpenFOAM case directory! Expected \"$case_base/constant\" to exist."  && exit 1
#[ ! -d "$case_base/0" ] && >&2 echo "Input is not an OpenFOAM case directory! Expected \"$case_base/0\" to exist."  && exit 1

# Demand that existing cases are gone before proceeding
[ -d "$case_ICgen" ] && >&2 echo "Case \"$case_ICgen\" already exists." && exit 1
[ -d "$case_run" ] && >&2 echo "Case \"$case_run\" already exists." && exit 1
[ -d "$case_us" ] && >&2 echo "Case \"$case_us\" already exists." && exit 1

#solver=$(cat "$case_base/system/controlDict" | grep "application" | sed 's/^application\s\+//g' | sed 's/;//g')
#echo "Found: solver=$solver"

# Source the optoFluids input file, which yields the variables (sim time, camera integration time, ...)
[ ! -f "$optoFluids_input" ] && >&2 echo "Input file \"$optoFLuids_input\" does not exist." && exit 1
source "$optoFluids_input"
# Sanity check the optoFluids input variables:
# (Error put at "else", because bash automatically goes to "else" when a floating point is inserted in the conditional.)
if [ "$sim_n_T" -ge 1 ]; then
	doNothing
else
	>&2 echo "\$sim_n_T=$sim_n_T, but should be an integer being 1 or larger."
	exit 1
fi
if [ "$presim_n_T" -ge 1 ]; then
	doNothing
else
	>&2 echo "\$presim_n_T=$presim_n_T, but should be an integer being 1 or larger."
	exit 1
fi
if [ "$cam_n_int" -ge 1 ]; then
	doNothing
else
	>&2 echo "\$cam_n_int=$cam_n_int, but should be an integer being 1 or larger."
	exit 1
fi
# TODO: cannot sanity-check sim_T etc., as they are floats...

## Prepare base case, if required.
echo "$case_base"
if [ -f "$case_base/prepareCase.sh" ]; then
	cd "$case_base" > /dev/null

	echo "Now running prepareCase.sh for \"$case_base\"..."

	# N.B.: Requires a dummy "system/controlDict" to be present in base!
	echo "\
	startTime=0
	endTime=1
	writeInterval=1 \
	" > "$control_input"
	templateSubstitutor.py -v "$control_input" -t system/controlDict.tmplt -o system/controlDict -f
	rm "$control_input"

	./prepareCase.sh || exit 1

	rm system/controlDict

	cd - > /dev/null
fi

# After-prepare Sanity Checks:
[ ! -f "$case_base/run.sh" ] && >&2 echo "Could not find \"run.sh\" in \"$case_base\". I don't know how to run this case!"  && exit 1

#################
## (1) Do a quick run to generate the IC for the true run.
##     This allows particles to disperse etc.
#####

echo "Now running \"$case_ICgen\"..."

## Prepare
# Create case
cp -r "$case_base" "$case_ICgen"
cd "$case_ICgen" > /dev/null

# Translate generic optoFluids input file to OpenFOAM language
# IC: Run the presim_T, and only write final result
echo "\
startTime=0
endTime=$presim_T
writeInterval=$(mathPy "float($presim_T)/$presim_n_T") \
" > "$control_input"
templateSubstitutor.py -v "$control_input" -t system/controlDict.tmplt -o system/controlDict -f
rm "$control_input"

## Run
./run.sh || exit 1 # Use run script that resides inside the base case

## Finish
# goback
cd - > /dev/null



#################
## (2) Now perform the run with large write intervals
##     So this is for the "Hz data sampling": not for mimicking an actual camera.
#####

echo "Now running \"$case_run\"..."

## Prepare
# Create case
cp -r "$case_base" "$case_run"

## Copy final result from IC case
latestTime="$(getLatestTime "$case_ICgen")" || exit 1
# Obtain processor directories
cd "$case_run" > /dev/null # cd to easily obtain a relative path to the processor directories
if [ $(isFoamCaseParallel) ]; then
	# Parallel: make an array of all processor directories
	procDirs=( $(echo "processor*") )
else
	# Serial: pretend the case is the only a processor directory
	procDirs=( "." )
fi
cd - > /dev/null
# Repeat copy process for each processor
for procDir in "${procDirs[@]}"
do
	#echo "procDir=$procDir"
	rm -rf "$case_run/$procDir/0"
	echo "-> Transfer from ""$case_ICgen/$procDir/$latestTime"" to ""$case_run/$procDir/0"
	cp -r "$case_ICgen/$procDir/$latestTime" "$case_run/$procDir/0"
	sed -i -e 's/'"$latestTime"'/0/g' "$case_run/$procDir/0/uniform/time"
done

# we are done with the old case --> goto new case
cd "$case_run" > /dev/null

# Translate generic optoFluids input file to OpenFOAM language
echo "\
startTime=0
endTime=$sim_T
writeInterval=$(mathPy "float($sim_T)/$sim_n_T") \
" > "$control_input"
templateSubstitutor.py -v "$control_input" -t system/controlDict.tmplt -o system/controlDict -f
rm "$control_input"

## Run
./run.sh || exit 1 # Use run script that resides inside the base case

## Finish
# goback
cd - > /dev/null


#################
## (3) For each data point of (2), start the microstepping process.
##     This mimics the "camera integration time" of a true camera.
#####

echo "Now running \"$case_us\"..."
echo "  preparing..."

## Prepare

# Copy $case_run to form the basis of $case_us (if two separate directories are used)
if [ ! "$case_run" == "$case_us" ]; then
    cp -r "$case_run" "$case_us"
fi

# we are done with the old case --> goto new case
cd "$case_us" > /dev/null

## Run
echo "  running..."
timeDirs=$(getTimeDirs)
writeInterval=$(mathPy "float($cam_t_int)/$cam_n_int")
for timeDir in ${timeDirs[@]}
do
	# Translate generic optoFluids input file to OpenFOAM language
	echo "\
	startTime=$timeDir
	endTime=$(mathPy "$timeDir+$cam_t_int")
	writeInterval=$writeInterval \
	" > "$control_input"
	templateSubstitutor.py -v "$control_input" -t system/controlDict.tmplt -o system/controlDict -f
	rm "$control_input"

	# Make sure dt <= writeInterval, otherwise no data will be generated
	# To do so, first get all procDirs
	if [ $(isFoamCaseParallel) ]; then
		# Parallel: make an array of all processor directories
		procDirs=( $(echo "processor*") )
	else
		# Serial: pretend the case is the only a processor directory
		procDirs=( "." )
	fi
	# Finally, substitute dt if required
	dt=$(cat "./${procDirs[0]}/$timeDir/uniform/time" | grep "deltaT " | sed -e 's/^\w\+\s\+//g' -e 's/;//g')
	if [ $(mathPy "$dt>$writeInterval") == "True" ]; then
		for procDir in "${procDirs[@]}"
		do
			sed -i -e 's/^\(deltaT0\?\s\+\).\+/\1'"$writeInterval"';/g' "$procDir/$timeDir/uniform/time"
		done
	fi
	# controlDict may be out-of-sync with uniform/time, so check it separately:
	dt=$(cat "./system/controlDict" | grep "deltaT " | sed -e 's/^\w\+\s\+//g' -e 's/;//g')
	if [ $(mathPy "$dt>$writeInterval") == "True" ]; then
		sed -i -e 's/^\(deltaT\?\s\+\).\+/\1'"$writeInterval"';/g' "system/controlDict"
	fi

	# Run for this $timeDir
	echo "  $timeDir"
	./run.sh || exit 1
done

## Finish
# goback
cd - > /dev/null


#################
## (4) PostProcess the "us" case if a script exists.
#####

if [ -f "$case_us/postProcessCase.sh" ]; then
	cd "$case_us" > /dev/null

	echo "Now running postProcessCase.sh for \"$case_us\"..."

	./postProcessCase.sh || exit 1

	cd - > /dev/null
fi






echo "Done."

# EOF
