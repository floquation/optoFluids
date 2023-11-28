#! /usr/bin/env bash


success=0
restartFrom=0
while [[ $success -eq 0 ]]
do
	reconstructPar -time $restartFrom: &> tempReconstrLog
	finished=$(grep -E "^End\.$" tempReconstrLog)
	if [[ "$finished" == "" ]]; then #have not successfully reconstructed
		#Now need to determine what particle is at fault from log
		echo "Reconstruction not finished correctly, attempting erroneous particle removal"
		faultyTime=$(grep -E "Time\s*=\s*[0-9]+\.?[0-9]*" tempReconstrLog | tail -1 | rev | cut -d " " -f 1 | rev) # the tail -1 takes the last match, and extracts the value from it
		restartFrom=$faultyTime #Ensure the next while iteration continues from the correct time
		faultyParticleLine=$(grep -E "\([0-9]*\.?[0-9]*[[:space:]][0-9]*\.?[0-9]*[[:space:]][0-9]*\.?[0-9]*\)" tempReconstrLog)
		faultyPosition="($(echo $faultyParticleLine | cut -d "(" -f 2)"
		faultyCellLine=$(grep -E "cell [0-9]+$" tempReconstrLog)
		faultyCell=$(echo $faultyCellLine | rev | cut -d " " -f 1 | rev)
		if [[ "$faultyParticleLine" == "" || "$faultyCellLine" == "" ]]; then
			echo "Search for faulty particle came up empty, probably a completely different error occured."
			echo "Stopping everything. Please analyze 'tempReconstrLog'."
			break 2 # Stop everything at once
		fi
		# Survived past the emptyness tests above? Let's fix the particle brothaaa aight! Lol.
		./removeErrParticle "$faultyPosition $faultyCell" "$faultyTime" &> particleRemoval_${faultyTime}_${faultyCell}.log # call the remover script		
		if [[ ! $(grep -E "^Done\!$" particleRemoval_${faultyTime}_${faultyCell}.log) == "" ]]; then
			echo "Succesfully finished particle removal script, check for errors of problems"
		else
			echo "Did not successfully finish particle removal script, aborting everything, check particle removal logs"
			break 2
		fi
	else #have successfully reconstructed this timestep
		echo "Parallel reconstruction complete"
		success=1 # so let's stop the while-age
		'rm' tempReconstrLog #Remove the temp log file
	fi
done

