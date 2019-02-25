#! /usr/bin/env python3
#
# This module contains several spatial (velocity) profiles, to-be-used by "moveParticles.py".
#  All profiles are callables with the same arguments.
#  All profiles are scaled to a mean of one.
#
# Kevin van As
#	23 11 2018: Original
#	05 02 2019: "constant" is now overloaded with the name "plug"
#	06 02 2019: Now gives a profile with mean one, instead of maximum one.
#

# Misc imports
import sys
# Numerics
import numpy as np # Matrices
# Import from optoFluids:
import geometries as geom

##
# Constant profile (i.e., plug flow) in the direction "shape.orientation"
def constant(pos, shape: 'Shape'):
	try: # Array input
		return np.ones((pos.shape[0],1)) * shape.orientation
	except: # Single input
		return np.reshape([1],(1,1)) * shape.orientation
def plug(pos, shape: 'Shape'):
	return constant(pos,shape)

##
# Hagen-Poiseuille flow (i.e., laminar cylindrical flow) in the direction "shape.orientation"
def Poiseuille(pos, shape: 'Cylinder'):
	# Check input
	if ( not isinstance(shape, geom.Cylinder) ):
		sys.exit("Poiseuille flow requires a cylindrical geometry, but was given a: " + str(type(shape)))
	# Deal with both array and singular:
	# TODO: x and y currently do not take orientation into account yet: they assume blindly that orientation=(0,0,1)
	try: # Array
		x = pos[:,0]
		y = pos[:,1]
	except: # Single: make them into an array of size 1
		x = [pos[0]]
		y = [pos[1]]
	#print(shape.origin)
	# Calculate profile:
	profile = (
			( shape.R ** 2 - (np.square(x-shape.origin[0]) + np.square(y-shape.origin[1])) )  # Poseuille like = R ^ 2 - r ^ 2
			/ (shape.R ** 2)	# Normalize = 1 - (r ^ 2) / (R ^ 2).
			)
	# Make its mean one:
	#print(profile)
	profile = profile * 2
	#print(pos/shape.R)
	#print(profile)
	#print("mean = " + str(np.mean(profile)))
	# Give it direction and appropriate matrix shape:
	profile = np.reshape(profile,(len(profile),1)) * shape.orientation
	# Done:
	return profile
	

