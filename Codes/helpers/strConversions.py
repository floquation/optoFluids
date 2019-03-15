#! /usr/bin/env python3
#
# Module that contains convenient from-string conversions.
#
# Kevin van As
#	01 03 2019: Original
#

# This function creates a CLI-interface for RTS with a non-constant arbitrary number of args and kwargs.
# Takes an input string of the form
# "a;b;c;d=1;e=2;f"
# and converts it to *args and **kwargs:
# ['a', 'b', 'c', 'f'] and {'d': '1', 'e': '2'}
# N.B.: "=" is always interpreted as a kwarg marker, so no element may contain "=".
def multiArgStringToArgs(argIn):
	# Validity
	if argIn == None: return [], dict() # no input -> no args
	# String to array:
	argsIn = argIn.split(';')
	# Split required and keyword arguments
	args=[]
	kwargs=[]
	for arg in argsIn:
		if "=" in arg:
			kwargs.append(arg)
		else:
			args.append(arg)
	return args, dict(arg.split('=') for arg in kwargs)

# like multiArgStringToArgs, but now reads
# "(a,b,c)" and converts it to a float vector: [a,b,c]
def strToFloatVec(argIn):
	# Validity
	if argIn == None: return None
	# String to array:
	if argIn[0] == "(" and argIn[-1] == ")":
		argIn=argIn[1:-1]
	argsIn = argIn.split(',')
	for i, arg in enumerate(argsIn):
		argsIn[i]=float(arg)
	return argsIn

# like multiArgStringToArgs, but now reads
# "(a,b,c)" and converts it to an int vector: [a,b,c]
def strToIntVec(argIn):
	# Validity
	if argIn == None: return None
	# String to array:
	if argIn[0] == "(" and argIn[-1] == ")":
		argIn=argIn[1:-1]
	argsIn = argIn.split(',')
	return strVecToIntVec(argsIn)

def strVecToIntVec(argIn):
	# Validity
	if argIn == None: return None 
	# String vector to vector:
	for i, arg in enumerate(argIn):
		argIn[i]=int(arg)
	return argIn
	




