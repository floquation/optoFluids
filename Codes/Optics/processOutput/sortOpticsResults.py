#! /usr/bin/env python3
#
#  This script takes an unsorted optics code (timeLooper[Parallel].py) output directory,
# and sorts by analysing the names of the intensity files.
# It detects the microsteps (dt_us) and the major steps (dt).
# Then, for each major step, it creates a new directory in which all
# associated microstep intensity files are placed.
#
# Example case:
#
# IN:
# dir
# | - Intensity_t0.out
# | - Intensity_t1.out
# | - Intensity_t2.out
# | - Intensity_t10.out
# | - Intensity_t11.out
# | - Intensity_t12.out
# | - Intensity_t13.out
# | - log
# \ - PixelCoords.out
# OUT:
# dir
# | - 0
#     | - Intensity_t0.out
#     | - Intensity_t1.out
#     \ - Intensity_t2.out
# | - 10
#     | - Intensity_t10.out
#     | - Intensity_t11.out
#     | - Intensity_t12.out
#     \ - Intensity_t13.out
# | - log
# \ - PixelCoords.out
# 
#
#
# Notes on preserveInputDir:
# if inputDir == outputDir:
#	move inputDir to a hidden version of the same directory,
#	e.g. "results" --> ".results".
#   Then proceed as if they inputDir != outputDir.
# else:
#	Apply "copy" instead of "move" for all files.
#
#
#
# Kevin van As
#   04 10 2018: Original
#	16 10 2018: Implemented "NameConventions"
#				Can use the "1D" and "2D" directories inside the input directory to detect location of Intensity/PixelCoords
#	19 10 2018: dt_us_tol criterion to deal with input precision errors (e.g., dt_us=3.9e-07 and dt_us=4.0e-07).
#				output directory names are now floats instead of strings: "0.0000" --> "0.0" and "0.000001" --> "1e-06"
#	29 11 2018: Implemented myRound in nameConventions
#

import re
import sys
import os.path
import shutil

# Import from optoFluids:
import helpers.regex as myRE
import helpers.nameConventions as names



DEFAULT_dt_us_tol=1.5


##############
## Worker class
####
class OpticsResultSorter(object):

	def __init__(self, inputDN, outputDN="", overwrite=False, verbose=False, preserveInputDir=False, dt_us_tol=DEFAULT_dt_us_tol):

		self.inputDN = inputDN
		if ( outputDN == "" or outputDN == None ):
			self.outputDN=inputDN
		else:
			self.outputDN=outputDN
		self.overwrite = overwrite
		self.verbose = verbose
		self.preserveInputDir = preserveInputDir

		self.dt_us_tol = float(dt_us_tol)

		########
		## Check validity of arguments
		####
		if  ( 	self.inputDN == "" or self.inputDN == None	):
			sys.exit("    Note: input directory cannot be an empty string or None:\n" + 
					 "     inputDir="+str(self.inputDN))
		#
		if ( os.path.exists(self.outputDN)):
			self.outputIsInput = os.path.samefile(self.inputDN, self.outputDN)
		else:
			self.outputIsInput = False
		#
		# Check for existence of the files
		if ( not os.path.exists(self.inputDN) ) :
			sys.exit("\nERROR: Inputfile '" + self.inputDN + "' does not exist.\n" + \
					 "Terminating program.\n" )
		if ( not self.outputIsInput and os.path.isdir(self.outputDN) and not self.overwrite ) :
			sys.exit("Output directory '" + self.outputDN + "' already exists, but overwrite=False.")

		# Done with init(). Note: Validity of input directory is evaluated in "run", while analysing the available times.

	def vprint(self, msg=""):
		if(self.verbose): print(msg)

	def unsortMsg(self,prefix=""):
		msg = str(prefix) + "$ echo \"" + str(self.outputDN) + "\"/[0-9]*/* results" + "\n" + \
			  str(prefix) + "$ mv \"" + str(self.outputDN) + "\"/[0-9]*/* results && rm -rf \"" + str(self.outputDN)+ "\"/[0-9]*" + "\n"
		return msg

	def preserveMove(self, src, trgt, preserve=False, recursive=False):
		if preserve:
			if recursive:
				shutil.copytree( src , trgt )
			else:
				shutil.copy2( src , trgt )
		else:
			shutil.move( src , trgt )

	def run(self):		
		##############
		## Analyse input directory times;
		## raise errors before doing any harmful operations
		####

		## 0) Detect location of the intensity files
		input1DDN = names.joinPaths(self.inputDN,names.input1DDN)
		input2DDN = names.joinPaths(self.inputDN,names.input2DDN)
		if ( os.path.exists(input2DDN) ):
			self.inputDN = input2DDN
			self.vprint("Found \"2D\" directory. Using it as input: " + str(self.inputDN))
		elif( os.path.exists(input1DDN) ):
			self.inputDN = input1DDN
			self.vprint("Found \"1D\" directory. Using it as input: " + str(self.inputDN))
		else:
			self.vprint("Did not find \"2D\" or \"1D\" directory. Using root as input: " + str(self.inputDN))
		if ( self.outputIsInput ) :
			self.outputDN = self.inputDN
		
		## 1) Read all intensity filenames with regex
		## 2) Make a list of all times; sort it numerically
		intFNRO = re.compile(names.intensityFNRE)
		resultFileList=os.listdir(self.inputDN)
		intFiles = myRE.getMatchingItemsAndGroups(resultFileList,intFNRO)
		# intFiles is now an array of tuples of the form: (filename, time)

		# Sort the times
		intFiles.sort(key=lambda time: float(time[1])) # sort by time, incl. exp.not.

		# Show found times to user:
		out="Found (sorted) times: "
		for FN,time in intFiles:
			out += time+" "
		self.vprint ( out )

		if (len(intFiles) == 0):
			sys.exit("Did not find any intensity files in the input directory ('"+self.inputDN+"'). Exiting.")
		if (len(intFiles) == 1):
			sys.exit("ERROR:\n" + \
					 " Only found one intensity files in the input directory ('"+self.inputDN+"'). Nothing to sort." + "\n" + \
					 " In case this directory was already sorted, and you wish to sort-in new files, then " + "\n" + \
					 " unsort it by hand before re-sorting it (echo to check first):\n" + \
					 self.unsortMsg(" ") + \
					 " Exiting.")

		## 3) Detect dt and dt_us
		deltaTimes = makeDeltaList(intFiles,1)
		self.vprint ("Resulting dts are:  " + str(deltaTimes))
		## 3a) Compare first and second timename, that is dt_us.
		dt_us = deltaTimes[0]
		## 3b) Make a list of indices in which the jump is larger than dt_us
		big_start_ilist=[0]
		data_lengths=[]
		prev=0
		for idt in range(len(deltaTimes)):
			#if ( deltaTimes[idt] != dt_us):
			if ( deltaTimes[idt] > self.dt_us_tol * dt_us):
				big_start_ilist.append(idt+1)
				data_lengths.append(idt+1-prev)
				prev=idt+1
		data_lengths.append(idt+2-prev)
		del prev
		self.vprint ("Big-step starting indices: " + str(big_start_ilist))
		self.vprint ("Big-step data lengths:     " + str(data_lengths))

		## 3c) Apply a check to make sure dt_us and dt are constants. Otherwise raise an error.
		if(len(big_start_ilist)>1): # else only one major timestep
			dt1 =  myRound(myRound(float(intFiles[big_start_ilist[1]][1])) - myRound(float(intFiles[0][1])))
			prev=0
			for i in range(1,len(big_start_ilist)):
				ijump=big_start_ilist[i]
				dt2 =  myRound(myRound(float(intFiles[ijump][1])) - myRound(float(intFiles[prev][1])))
				self.vprint("("+str(i)+") Found major dt = " + str(dt2))
				if ( dt1 != dt2 ):
					sys.exit("ERROR\n" + \
							 " Found different major timesteps: dt1="+str(dt1)+", dt2="+str(dt2)+".\n" + \
							 " Terminating without sorting.")
				prev=ijump
			del prev
			
		## 4) Make an array of the different sets of microsteps
		sortedFNs=[]
		sortedMajorTimes=[]
		self.vprint("Sorted filenames: ")
		for i in range(len(big_start_ilist)):
			#print(i)
			sortedMajorTimes.append(intFiles[big_start_ilist[i]][1])
			tupleMaker=()
			for j in range(big_start_ilist[i],big_start_ilist[i]+data_lengths[i]):
				#print(" " + str(j))
				tupleMaker += (intFiles[j][0],)
			self.vprint(" " + str(tupleMaker))
			sortedFNs.append(tupleMaker)
			
		self.vprint("Major start times: " + str(sortedMajorTimes))


		##############
		## Sort times into output directory
		####

		# Pre-check the existence of (sorted) major-time directories if outputIsInput
		# and exit if it already exists. Then apparently this directory was already sorted.
		# Cannot sort twice (presently)!
		if ( self.outputIsInput ):
			for time in sortedMajorTimes:
				dirOut = os.path.join( self.outputDN, names.intensitySortedDN(time) )
				if ( os.path.exists(dirOut) ):
					sys.exit("ERROR:\n" + \
							" Majortime directory ('"+str(dirOut)+"') already exists.\n" + \
							" Presumably this directory was already sorted?\n" + \
							" If so, unsort it by hand before re-sorting it (echo to check first):\n" + \
							self.unsortMsg(" ") + \
							" Exiting.")

		###
		## All checks are done. From now on we may safely apply irreversible operations.
		###

		#  Move the inputDir to outputDir.
		# Then we can treat self.outputIsInput True and False alike:
		# outputDir is then both the source as the target!
		if ( not self.outputIsInput ):
			# move/copy (depending on self.preserveInputDir) inputDir to outputDir
			if ( os.path.exists(self.outputDN) and self.overwrite ):
				shutil.rmtree(self.outputDN)
			self.preserveMove( self.inputDN, self.outputDN , self.preserveInputDir, recursive=True)
		elif ( self.preserveInputDir ):
			#  preserve inputDir by moving it to a hidden directory of the same name;
			# then copy it to outputDir such that we can treat outputDir as if it was the inputDir
			self.inputDN = os.path.join(os.path.dirname(self.inputDN), "." + os.path.basename(self.inputDN))
			self.vprint("Preserving input \"" + str(self.outputDN) + "\" to \"" + str(self.inputDN) + "\".")
			if ( os.path.exists(self.inputDN) ):
				if (self.overwrite):
					shutil.rmtree(self.inputDN) # overwrite preserve location
				else:
					sys.exit("ERROR\n" + \
							 " Trying to preserve input '" + self.outputDN + \
							 "' to '" + self.inputDN + "', but this directory already exists." + "\n" + \
							 " Use -f to overwrite.\n" \
							 " Exiting."
					)
			shutil.move(self.outputDN, self.inputDN)
			shutil.copytree(self.inputDN, self.outputDN)

		# 5) Make a directory for each main timename
		dirOutList=[]
		for time in sortedMajorTimes:
			# Convert to float to str, such that "0.000000" is just "0.0", and "0.000001" is "1e-06".
			dirOut = os.path.join( self.outputDN,str(float(time)) )
			os.makedirs( dirOut ) 
			dirOutList.append(dirOut)

		# 6) Move all intensity files to the appropriate directory:
		for iset in range(len(sortedFNs)):
			dirOut = dirOutList[iset]
			for FN in sortedFNs[iset]:
				self.vprint("Moving: " + str(FN)  + " --> "  + str(dirOut))
				shutil.move ( os.path.join( self.outputDN, FN ) , dirOut )





########
## Non-class functions
####

# Round to 9 significant digits:
def myRound(value):
	return names.myRound(value) #float('%.8e' % value)

# Take a list of tuples in which the index'd element is float.
# Return a list of length N-1 with the delta values.
def makeDeltaList(lstIn, index=0):
	lstOut=[]
	for i in range(len(lstIn)-1):
		lstOut.append( myRound( float(lstIn[i+1][index]) - float(lstIn[i][index]) ) )
	return lstOut




##############
## Command-Line Interface (CLI)
####
if __name__=='__main__':
	import optparse
	class CLI(object):
		usageString = "   usage: %prog -i <inputDir> [options]"
		#requiredOpts = "a b c".split()
		requiredOpts = "inputDir".split()

		def parse_options(self):
			parser = optparse.OptionParser(usage=self.usageString)
			parser.add_option('-i', dest='inputDir',
				help="optics results directory to-be-sorted")
			parser.add_option('-o', dest='outputDir', default="",
				help="sorted output directory, defaults to -i")
			parser.add_option("-f", action="store_true", dest="overwrite", default=False,
				help="force overwrite output? [default: %default]")
			parser.add_option("-p", action="store_true", dest="preserveInputDir", default=False,
				help="preserve input directory? [default: %default]")
			parser.add_option("--tol", type="float", dest="dt_us_tol", default=DEFAULT_dt_us_tol,
				help="the step between the last time of the microstepping to the next major timename is greater than \"tol\".\n" + \
					"This allows non-constant dt_us to be seen as \"the same\" microstep.\n" + \
					"For example, a value of 1.5 gives a 50% tolerance for the microstep names (dt_us)" + \
					", which works as long as there is at least 1.5*dt_us between the last microstep timename and the next major timename\n" + \
					"[default: %default]")
			(self.opt, self.args) = parser.parse_args()

			for r in self.requiredOpts:
				if self.opt.__dict__[r] is None:
					parser.error("Parameter '%s' is required!"%r)

		def run(self):
			self.parse_options()        
			OpticsResultSorter(
				inputDN=self.opt.inputDir,
				outputDN=self.opt.outputDir,
				overwrite=self.opt.overwrite,
				preserveInputDir=self.opt.preserveInputDir,
				dt_us_tol=self.opt.dt_us_tol,
				verbose=True
			).run()

	CLI().run()



# EOF
