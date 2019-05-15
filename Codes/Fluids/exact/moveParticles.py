#! /usr/bin/env python3
#
# This script takes a list of initial particle positions
#  (either as a file, or as a numpy array),
#  and then evolves the particle positions as a function
#  of time, given a spatial profile and a temporal modulation.
# 
# Jorne Boterman
#   01 01 2017:? Original in Matlab
# Hidde van Ulsen
#	01 10 2018:? Port to Python
# Kevin van As
#	23 11 2018: Made it neat, with RTS and CLI
#	26 11 2018: Added temporal modulation structure (still unused)
#	29 11 2018: repeatEvolve, outputDN
#	06 12 2018: t_int, n_int, T and n via CLI and its sanity checks
#	01 02 2019: t=0 now also obeys the (periodic) BC, which prevents t=0 from having completely different speckles than t=veryveryshort.
#	05 02 2019: Now uses MEAN velocity, instead of MAXimum velocity.
#	05 04 2019: Implemented enhanced RTS "select" functionality by deleting lines that are now no longer necessary.
#	15 05 2019: Implemented T=0 stop checks correctly. In that case this code simply writes the IC to t=0.
#
# TODO:
#	Set origin, orientation from CLI
#	Set starttime from CLI? Currently read from file, which is already nice...?
#	

# Misc imports
import re
import sys
import os.path, shutil
from io import StringIO

import inspect
#import traceback

# Numerics
import numpy as np # Matrices

## Typing
#import typing.Union

# Import from optoFluids:
import helpers.regex as myRE
import helpers.nameConventions as names
import helpers.RTS as RTS
import geometries as geom
import spatialProfiles, temporalModulation

class MoveParticles(object):
	"""
	MoveParticles takes as input a file with on each line (X Y Z) coordinates of a particle,
	and evolves the z direction of that particle in time according to plug flow or a Poseille (R ^ 2 - r ^ 2) profile.
	Periodic boundary conditions are applied.
	Output is a a file for each timestep with the (X Y Z) coordinates of each particle

	Assumptions:
	Particles move in the z-direction
	X,Y origin is centered around (0,0)

	Usage:
	MoveParticles may be called in another Python file as follows:
	from parentDir.filename import ClassName as mymodule
	MoveParticles(input1_mandatory="a",input2_optional="b").run()
	Or it may be used from the command-line as follows, using the CLI:
	filename.py -a "value1" -b "value2"
	"""

	########
	## Constructors
	####

	def __init__(self, umean: float, spatialProfile, geometry, temporalModulation="none", outputDN="pos", starttime=0, verbose=False, overwrite=False):
	#def __init__(self, particlePosFileName: str, outputFolder: str, t_total: float, t_start: float, u: float, n_samples: int,
	#			 flow_type: str, z_min: float, z_max: float, cyl_radius: float, overwrite, verbose=False):
		"""
		Initialize the class and check if input files exist and/or can be overwritten.

		:param particlePosFileName: input file
		:param outputFolder: output folder (with trailing slash)
		:param t_total: total time we want to evolve particles over in seconds
		:param u: average velocity of flow in meters per second
		:param n_samples: amount of samples we want to have
		:param flow_type: "plug" or "pois" flow
		:param z_min: first z-coordinate in mm
		:param z_max: last z-coordinate in mm
		:param cyl_radius: radius of the cylinder in mm
		:param overwrite: overwrite the already existing output files, true or false
		:param verbose: output debug message, true or false
		"""

		# Set these class member variables first
		self.verbose = verbose
		self.overwrite = overwrite
		self.setTime(starttime)
		self.setOutputDN(outputDN)

		# Then set the other member variables 
		self.data = None # List of particle position vectors
		try:
			self.umean = float(umean) # Mean velocity
		except:
			sys.exit("Velocity umean must be numeric, but received: " + str(type(umean)))
		self.setSpatialProfile(spatialProfile) # Callable that gives u(\vec{r})
		self.setTemporalModulation(temporalModulation) # Callable that gives F(t) such that v(r,t)=u(r)F(t)
		self.geometry = geometry
		
	
	########
	## I/O functions
	####

	def readData(self, FN):
		# Check arguments
		if ( FN is None or FN == "" ):
			sys.exit("InvalidArgument: data filename cannot be None or \"\".\n" + str(locals()))
		if ( not os.path.exists(FN) ):
			sys.exit("\nERROR: Inputfile '" + FN + "' does not exist.\n" +
					 "Terminating program.\n")
		
		# Read start time from the particle positions file (if possible)
		try:
			groups = myRE.getMatchingGroups(names.basename(FN), re.compile(names.particlePositionsFNRE))
			self.setTime(groups[0])
		except:
			pass

		# Read inputfile and remove "(" and ")"
		dataFile = open(FN)
		dataStr = dataFile.read().replace("(", "").replace(")", "").strip()
		# skip_header to skip the first two lines of the input file, which are (line 1) the number of particles integer and (line 2) just an opening bracket
		self.setData(np.genfromtxt(StringIO(dataStr), skip_header=2))
		dataFile.close()

	def setData(self, array):
		# TODO: Validity check
		self.data = array
		self.vprint("setData = " + str(self.data))

	def writeToFile(self, FN=None):
		#outputFile = self.outputFolder + "particlePositions_t" + "{:.8f}.txt".format(
		#	self.t_start + (j * self.t_total / (self.n_samples - 1))) #format well

		if FN == None or FN == "":
			FN = self.generatePosFN(self.time)

		if os.path.exists(FN) and not self.overwrite:
			sys.exit("\nERROR: Outputfile '" + FN + "' already exists.\n" +
					 "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n")

		# Create output directory if needed
		if not os.path.exists(self.outputDN):
			os.mkdir(self.outputDN)

		f = open(FN, "w+")
		f.write(str(len(self.data)) + "\n")
		f.write("(\n")
		for k, particle in enumerate(self.data):
			f.write("(%0.15f %0.15f %0.15f)\n" % (self.data[k, 0], self.data[k, 1], self.data[k, 2]))
		f.write(")")
		f.close()
		

	########
	## Worker functions
	####
	def moveOnce(self, dt):
		if dt == None: raise ValueError("Received dt="+str(dt)+", but expected a numeric value (float).")
		profile = self.spatialProfile( self.data, self.geometry )
		Ft = self.temporalModulation( self.time )
		self.vprint("    Ft = " + str(Ft))
		#print(self.data)
		self.data = self.data + profile * self.umean * Ft * dt # update position dx = u * dt
		self.time = self.time + dt # tick
		#print(self.data)
		#profile = self.spatialProfile( (0,0,0), self.geometry )
		#print( profile * self.umean * dt )
		self.applyBC(periodic=True) # constrain in geometry

	# Evolve particle positions (self.data) from t00 to t00+T with step dt
	def evolveFor(self, dt, T, write=False):
		t00=self.time # t00 := start time
		self.vprint("self.evolveFor(dt="+str(dt)+", T="+str(T)+", write="+str(write)+") called from t="+str(t00)+":")
		if dt == None: raise ValueError("Received dt="+str(dt)+", but expected a numeric value (float).")
		if(T==0): self.vprint("T=0, so nothing to evolve: returning."); return # Evolve for zero time? We're already done!
		t0=t00 # t0 := last time, t1 := new (target) time
		i=0 # Use a counter to negate accumulation of rounding errors of continuing adding a rounded dt
		done = False
		while( not done ) :
			i=i+1
			if ( t0 + dt*1.01 > t00 + T): # Stop precisely after T by decreasing the last dt (or increasing the prelast dt by 1% to prevent dt=O(eps) for last step)
				t1 = t00 + T
				done = True
			else: # Regular stepping with dt
				t1 = t00 + i*dt
			self.vprint("  (t0,t1,dt) = ( " + str(t0) + "," + str(t1) + "," + str(t1-t0) + ")")
			self.moveOnce(t1-t0)
			t0=t1
			#print(self.data)
		if(write):
			self.writeToFile()

	# Calls "evolveFor" repetitively, and writes a total of nWrite files during T. If wrwiteStart=True it additionally writes the starttime
	def repeatEvolve(self, dt, T, nWrite, writeStart=True):
		self.vprint("self.repeatEolve(dt="+str(dt)+", T="+str(T)+", nWrite="+str(nWrite)+", writeStart="+str(writeStart)+") called")
		if T==None or nWrite==None: raise ValueError("Received T="+str(T)+" and nWrite="+str(nWrite)+", but expected T=float, nWrite=int.")
		if writeStart:
			self.moveOnce(dt=0) # Make sure that t=0 obeys the same BCs as the future times to prevent an instant change in speckle.
			self.writeToFile()
		if(T==0): self.vprint("T=0, so nothing to evolve: returning."); return # Evolve for zero time? We're already done!
		if nWrite>0:
			Tper = float(T)/nWrite
		else:
			raise ValueError("Received nWrite="+str(nWrite)+", but expected a positive integer.")
		for i in range(nWrite):
			self.evolveFor(dt,Tper, write=True)

	def multiRepeatEvolve(self, dt, T, nWrite, writeStart=True):
		self.vprint("self.multiRepeatEvolve(dt="+str(dt)+", T="+str(T)+", nWrite="+str(nWrite)+", writeStart="+str(writeStart)+") called")
		# Sanity checks
		if type(T) == tuple:
			if type(nWrite) != tuple or len(T) != len(nWrite):
				raise ValueError('T and nWrite should be of the same length, but received T=' + str(T) + ", nWrite=" + str(nWrite) + ".")
		else: #regular self.repeatEvolve should have been called...
			return self.repeatEvolve(dt,T,nWrite,writeStart)
		if len(T) != 2:
			raise ValueError('T='+str(T)+' has length ' + str(len(T)) + ', but this function only supports a length of 2.')

		# Ensure proper typing and ~None:
		for i in range(len(T)):
			if T[i] == None:
				if not nWrite[i] == None:
					raise ValueError('Received T='+str(T)+' and nWrite='+str(nWrite)+". I don't know how to interpret that! Inconsistent Nones: " + 
										"the same t and the same n should be set.")
			elif nWrite[i] == None:
				raise ValueError('Received T='+str(T)+' and nWrite='+str(nWrite)+". I don't know how to interpret that! Inconsistent Nones: " + 
									"the same t and the same n should be set.")
			if type(T[i]) == str: # Cast str to float
				T[i] = float(T[i])
			if type(nWrite[i]) == str: # Cast str to int
				nWrite[i] = int(nWrite[i])
			# Else continue and hope typing is OK.
		# 2x None? Then self.repeatEvolve should have been called!:
		for i in range(len(T)):
			if T[i] == None and nWrite[i] == None:
				iGood=(i-1)%len(T)
				return self.repeatEvolve(dt,T[iGood],nWrite[iGood],writeStart)

		# Ensure T is ascending, as the remainder of this code assumes that
		if T[0] > T[1]:
			T = ( T[1], T[0] )
			nWrite = ( nWrite[1], nWrite[0] )

		# Prepare for evolving
		t00 = self.time
		if nWrite[1]>0:
			Tper = float(T[1])/nWrite[1]
		else:
			raise ValueError("Received nWrite_total="+str(nWrite[1])+", but expected a positive integer.")
		# Evolve start optionally:
		if writeStart:
			# do microstepping for starting time as well
			self.repeatEvolve(dt, T[0], nWrite[0], writeStart=True)
		# Evolve:
		if(T[1]==0): self.vprint("Both T=0, so nothing to evolve: returning."); return # Evolve for zero time? We're already done!
		for i in range(nWrite[1]):
			# jump to next major step
			target_major = t00 + (i+1)*Tper
			Tjump = target_major - self.time
			self.vprint("[" + str(self.time) + "]")
			self.evolveFor(dt,Tjump, write=True)
			#print("time in between = " + str(self.time))
			# do microstepping
			self.repeatEvolve(dt, T[0], nWrite[0], writeStart=False)
			#print("time after = " + str(self.time))

	# Bound/Constrain the particles by the geometry
	def applyBC(self, periodic):
		for k, particle in enumerate(self.data):
			self.data[k] = self.geometry.constrain(particle, periodic=periodic)

	########
	## Setters
	####
	def setSpatialProfile(self, prof):
		self.vprint("setSpatialProfile: " + str(prof))
		self.spatialProfile = RTS.select(spatialProfiles, str(opt.spatProf))

	def setTemporalModulation(self, mod, *args, **kwargs):
		self.vprint("setTemporalModulation: " + str(mod))
		self.temporalModulation = RTS.select(temporalModulation, str(mod), *args, **kwargs)

	def setOutputDN(self, DN):
		# Check for existence of the files
		if DN is None or DN == "":
			raise ValueError('The output directory name cannot be None or \"\".')
		if os.path.exists(DN) and not self.overwrite and not DN==".": # Allow writing in "." even without overwrite
			raise ValueError('The output directory "' + str(DN) + '" already exists, and overwrite=False.')
		if os.path.exists(DN) and self.overwrite:
			# Check if DN only contains position files. If so, replace the directory. If not, append new files to the directory (which possibly overwrite existing ones).
			files=os.listdir(DN)
			self.vprint("Note: Output directory already contained position files. Fraction = "
				+ str(myRE.countMatchingItems(files, re.compile(names.particlePositionsFNRE)))
				+ "/" + str(len(files))
			)
			if len(files) == myRE.countMatchingItems(os.listdir(DN), re.compile(names.particlePositionsFNRE)):
				shutil.rmtree(DN)
				self.vprint(" All those files are position files. Replace them all.")
			else:
				self.vprint(" Not all were position files. Do not replace directory, but rather append new files and overwrite files with the same name.")
				
		# Accepted. Store output directory name.
		self.outputDN = DN

	def setTime(self, time):
		self.time = float(time)
	

	########
	## Utility functions
	####
	def vprint(self, msg=""):
		if self.verbose:
			print(msg)

	# Generate a name for the particlePositions filename using nameConvention
	def generatePosFN(self, time):
		return names.joinPaths(self.outputDN,names.particlePositionsFN(time))


if __name__ == '__main__':
	import optparse

	usageString = "usage: %prog -i <positionsfile> -o <outputfolder> [options]"

	# Init
	parser = optparse.OptionParser(usage=usageString)
	(opt, args) = (None, None)

	# Parse options
	parser.add_option('-i', dest='partPosFN',
						   help="filename of the particle positions"),
	parser.add_option('-o', dest='outputDN', default=".",
						   help="name of the output directory")
#	parser.add_option('--t_start', dest='t_start',
#						   help="start time of the simulation")
	parser.add_option('-u', dest='umean',
						   help="mean speed of the flow (both in space and time)")
	parser.add_option('-d', '--dt', dest='dt', type="float",
						   help="Timestep used for numerical integration. If the writeInterval is lower than dt, then a lower dt is automatically used.")
	parser.add_option('-T', dest='t_total', type="float",
						   help="Total simulation time period")
	parser.add_option('-n', dest='n_total', type="int",
						   help="Number of write samples during the total time period (T). Since t=0 is already there, you'll have n+1 datafiles.")
	parser.add_option('--t_int', dest='t_int', type="float",
						   help="Camera integration time")
	parser.add_option('--n_int', dest='n_int', type="int",
						   help="Number of camera integration samples. You'll have n+1 datafiles for each camera integration.")
	parser.add_option('--flow', dest='spatProf',
						   help="spatial flow profile, one of: " + str(RTS.getFunctions(spatialProfiles)))
	parser.add_option('--mod', dest='tempMod', default="none",
						   help="temporal flow modulation, one of: " + str(RTS.getFunctions(temporalModulation)))
	parser.add_option('--modargs', dest='tempMod_args',
						   help="Required arguments for the temporal flow modulation (if any). Separate the parameters with a comma (e.g., --modargs \"a,b\").")
	parser.add_option('-L', dest='cyl_length',
						   help="length of cylinder")
	parser.add_option('--origin', dest='origin', default="(0,0,0)",
						   help="origin '(x,y,z)' of cylinder")
	parser.add_option('-R', dest='cyl_radius',
						   help="radius of cylinder")
	parser.add_option("-v", action="store_true", dest="verbose", default=False,
						   help="verbose [default: %default]")
	parser.add_option("-f", action="store_true", dest="overwrite", default=False,
						   help="force overwrite output? [default: %default]")
	(opt, args) = parser.parse_args()
	
	# Define geometry
	origin=RTS.strToFloatVec(opt.origin)
	myGeom = geom.Cylinder(R=opt.cyl_radius, L=opt.cyl_length, origin=origin) # TODO: orientation, optional shape (i.e., other than cylinder)

	#myGeom = geom.Cylinder(R=opt.cyl_radius, L=opt.cyl_length, origin=[0, 0 ,0], orientation=[1, 2, 0])
	#particle = [-1e-3, 0, 0]
	#print(myGeom.constrain(particle, False))
	##print(particle) # The same, so pass-by-value is used.
	#exit()

	# Prepare moveParticles
	mover = MoveParticles(
		umean=opt.umean,
		spatialProfile=opt.spatProf,
		geometry=myGeom,
		outputDN=opt.outputDN,
		verbose=opt.verbose,
		overwrite=opt.overwrite
	)
	(tempMod_args, tempMod_kwargs) = RTS.multiArgStringToArgs(opt.tempMod_args)
	#print("temporalModulation args: " + str(tempMod_args) + "; kwargs: " + str(tempMod_kwargs) + ".")
	mover.setTemporalModulation(opt.tempMod, *tempMod_args, **tempMod_kwargs)
	mover.readData(opt.partPosFN)


	# Testing
	#mover.setTemporalModulation("lookupTable", *(2, 3), boundaryStrategy="b")
	#mover.moveOnce(0.001)
	#mover.evolveFor(dt=0.001,T=0.0031)
	#mover.writeToFile()
	#mover.writeToFile(names.joinPaths(".",names.particlePositionsFN(1e-3)))
	#mover.repeatEvolve(dt=0.001,T=0.1, nWrite=10, writeStart=True)
	#mover.multiRepeatEvolve(dt=0.001,T=(0.001, 1), nWrite=(2,10), writeStart=True)

	# Run
	mover.multiRepeatEvolve(dt=opt.dt, T=(opt.t_int, opt.t_total), nWrite=(opt.n_int, opt.n_total), writeStart=True)





# EOF
