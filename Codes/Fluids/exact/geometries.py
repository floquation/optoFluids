#! /usr/bin/env python3
#
# This script defines several (geometric) shapes, such as a cylinder.
#
# Kevin van As
#	23 11 2018: Original
#	26 11 2018: Added "constrain", also for arbitrary orientation
#

# Numerics
import numpy as np # Matrices


class Shape(object):
	def __init__(self, orientation=(0,0,1), origin=(0,0,0)):
		self.orientation = orientation/np.linalg.norm(orientation) # Unit vector parallel to cylinder axis
		self.origin = origin # Center point of bottom circle
		if ( len(orientation) != 3 ):
			sys.exit("InvalidArgument: \"orientation\" should be a vector of size 3, but was: " + str(orientation) + ".")
		if ( len(origin) != 3 ):
			sys.exit("InvalidArgument: \"origin\" should be a vector of size 3, but was: " + str(origin) + ".")
		#print("orientation = " + str(self.orientation))

class Cylinder(Shape):
	# Orientation // axis of cylinder
	# Origin is the center of the base circle of the cylinder
	def __init__(self, L, R, orientation=(0,0,1), origin=(0,0,0)):
		super().__init__(orientation,origin)
		self.L = float(L) # Length of cylinder
		self.R = float(R) # Radius of cylinder

	# Constrain the particle between z_min and z_max in the direction of self.orientation.
	# The radial direction remains unchecked.
	def constrain(self, particle, periodic=True):
		# Make sure we have a numpy array:
		try:
			particle - particle
		except:
			particle = np.array(particle)
		# Compute:
		#print("posIn = " + str(particle))
		shift = self.origin + self.L/2 * self.orientation # Define coordinate shift such that origin is in the center of the cylinder, because then + and - case are symmetric.
		#print("shift = " + str(shift))
		posRel  = particle - shift # shift to coordinate system of cylinder
		#print("posRel = " + str(posRel))
		proj    = np.dot(posRel, self.orientation) # project on cylinder axis
		#print("proj = " + str(proj))
		if periodic: # Constrain with periodic/cyclic BC
			proj2   = proj - int(proj/self.L + np.sign(proj)*0.5)*self.L # shift with modulo #TODO: undershoot
			#print("modulo-term = " + str(int(proj/self.L + np.sign(proj)*0.5)*self.L) + " --> " +  str(int(proj/self.L + np.sign(proj)*0.5)*self.L * self.orientation) )
			#print("proj2 = " + str(proj2))
			#posRel2 = posRel - ( proj - proj2 ) * self.orientation # reconstruct relative vector
			posRel2 = posRel - ( int(proj/self.L + np.sign(proj)*0.5)*self.L ) * self.orientation # Apply modulo calculation in the self.orientation direction
			#print("posRel2 = " + str(posRel2))
			#print("project result back = " + str(np.dot(posRel2, self.orientation)))
		else: # Constrain with minmax
			if abs(proj) > self.L/2:
				#print("minmax")
				posRel2 = posRel - ( proj - np.sign(proj)*self.L/2 ) * self.orientation # reconstruct relative vector: go to point -L/2 along axis
				#print("posRel2 = " + str(posRel2))
			else: # Already inside cylinder
				#print("doNothing")
				posRel2 = posRel
			
		pos = posRel2 + shift # reconstruct global vector
		#print("posOut = " + str(pos))
		return pos


	def constrainOld(self,particle,periodic=True): # Only works with orientation = (0,0,1)
		print(particle)
		z_min = self.origin[2]
		z_max = self.origin[2] + self.L
		if particle[2] > z_max:
			if(periodic):
				particle[2] = ( z_min + ((particle[2] - z_max) % self.L ) )
			else:
				particle[2] = z_max
		if particle[2] < z_min:
			if(periodic):
				particle[2] = ( z_max - ((z_min - particle[2]) % self.L ) )
			else:
				particle[2] = z_min
		return particle

