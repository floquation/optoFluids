#! /usr/bin/env python3
#
# Module that handles run-time selection (RTS).
#  'getFunctions(moduleName)' returns an array with available callables
#  'select(fromModuleName,itemName,*itemargs,**itemkwargs)' returns a callable
#  'multiArgStringToArgs(argString)':
#	takes a comma-separated string and returns *args as array and **kwargs as a dict.
#	Useful for CLI with a variable number of positional and keyword arguments.
# 
# Kevin van As
#	23 11 2018: Original
#	03 12 2018: multiArgStringToArgs
#
# TODO: Return meaningful error when construction fails in select(): What parameters did the constructor require?

import inspect

def getFunctions(obj, verbose=False, onlyPublic=True):
	funcs=[]
	for i in inspect.getmembers(obj):
		# Ignores anything starting with underscore 
		# (that is, private and protected attributes)
		if ( ( not onlyPublic ) or not i[0].startswith('_') ):
			if inspect.ismethod(i[1]): continue # Ignores methods #TODO: Is that appropriate?
			if inspect.ismodule(i[1]): continue # Ignore imported modules ("import foo")
			if i[1].__module__ != obj.__name__: continue # Ignore imported functions ("from foo import bar")
			if verbose:
				funcs.append(i)
			else:
				funcs.append(i[0])
	return(funcs)

def select(module, name, *args, **kwargs):
	attr = getattr(module, str(name))
	#print("type = " + str(type(attr)))
	if inspect.isclass(attr):
		#print("is a ClassType")
		return attr(*args, **kwargs)
	return attr
	
# This function creates a CLI-interface for RTS with a non-constant arbitrary number of args and kwargs.
# Takes an input string of the form
# "a,b,c,d=1,e=2,f"
# and converts it to *args and **kwargs:
# ['a', 'b', 'c', 'f'] and {'d': '1', 'e': '2'}
# N.B.: "=" is always interpreted as a kwarg marker, so no element may contain "=".
def multiArgStringToArgs(argIn):
	# Validity
	if argIn == None: return [], dict() # no input -> no args
	# String to array:
	argsIn = argIn.split(',')
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
	if argIn == None: return [], dict() # no input -> no args
	# String to array:
	if argIn[0] == "(" and argIn[-1] == ")":
		argIn=argIn[1:-1]
	argsIn = argIn.split(',')
	for i, arg in enumerate(argsIn):
		argsIn[i]=float(arg)
	return argsIn

