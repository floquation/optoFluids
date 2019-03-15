#! /usr/bin/env python3
#
# This module provides several useful print and write2file functions.
# 
# Kevin van As
#	13 12 2018: Original: Printer class and writeNColFile
#	04 03 2019: Added "addSpaces" which may be used to better align output, for example:
#				myPrint.addSpaces(":",
#					30 - len(str(thing_with_variable_length))
#				)
#
#
# TODO: Write in arbitrary file format in writeNColFile
# TODO: Accept 2D numpy arrays (np.ndarray) in writeNColFile

import os.path
import sys

try:
    import __builtin__
except ImportError:
    # Python 3
    import builtins as __builtin__

# Print-to-stdout class which can keep track of an indent level using
# its push() and pull() functions. The indent level is to prefix
# "prefixer" N times in front of all messages, allowing for structured
# indented output messages.
# Also provides an verbose option to enable/disable debug messages.
class Printer:
	prefixer="  "
	verbose=False
	prefixLevel=0

	@staticmethod
	def push():
		Printer.prefixLevel = Printer.prefixLevel + 1
		#Printer.prefix = Printer.prefix + Printer.prefixer

	@staticmethod
	def pull():
		#Printer.prefix = Printer.prefix[:-len(Printer.prefixer)]
		Printer.prefixLevel = max(Printer.prefixLevel - 1, 0)

	@staticmethod
	def makePrefix():
		prefix=""
		for i in range(Printer.prefixLevel):
			prefix = prefix + Printer.prefixer
		return prefix

	@staticmethod
	def print(*args, **kwargs):
		__builtin__.print(Printer.makePrefix() + str(*args), **kwargs)

	@staticmethod
	def vprint(msg, verbose=None):
		if(verbose==None): verbose=Printer.verbose
		if(verbose): Printer.print(msg)

def addSpaces(string, num):
	for i in range(0,num):
		string = string + " "
	return string

def writeNColFile(FN, *colArrays, sep=" ", writePrecision=10, writeStyle='e', overwrite=False):
	## Prepare / Checks
	toFile=True
	if FN == None or FN == "":
		toFile=False
		printFunc=print
	else:
		if os.path.exists(FN) and not overwrite:
			sys.exit("\nERROR: Outputfile '" + FN + "' already exists.\n" +
					 "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n")
		# Create output directory if needed
		DN = os.path.dirname(FN)
		if not DN=="" and not os.path.exists(DN):
			os.mkdir(os.path.dirname(FN))

	sepLen=len(sep)
	maxLen=0
	for data in colArrays:
		maxLen=max(maxLen,len(data))
	formatter="%."+str(writePrecision-1)+str(writeStyle)+"%s"

	## Start Writing
	if toFile:
		f = open(FN, "w+")
		printFunc=f.write
	for i in range(maxLen):
		lineStr = ""
		#for j in range(len(data[i,:])):
			#lineStr = lineStr + (formatter % (data[i,j],sep) )
		for col in colArrays:
			lineStr = lineStr + (formatter % (col[i],sep) )
		lineStr = lineStr[:-sepLen] # Remove last separator
		if toFile: lineStr = lineStr + "\n"
		printFunc(lineStr)
	if toFile: f.close()



