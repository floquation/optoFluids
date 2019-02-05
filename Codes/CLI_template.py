#! /usr/bin/env python3
#
# This script ...
#  Second line of same paragraph.
# New paragraph.
#
# ClassName may be called in another Python file as follows:
#  from parentDir.filename import ClassName as mymodule
#  mymodule(input1_mandatory="a",input2_optional="b").run()
# Or it may be used from the command-line as follows, using the CLI:
#  filename.py -a "value1" -b "value2"
#
# Kevin van As
#   09 09 2018: Original
#   10 09 2018: Updated this thing.
#

import re
import sys
import os.path
#import numpy as np

# Import from optoFluids:
#from templating.templateSubstitutor import TemplateSubstitutor as ts

##############
## Worker class
####
class ClassName(object):

    # class_var1="" # You do not have to specify class-variables in objective-Python. They are declared and initialised in __init__.

    def __init__(self, input1_mandatory, input2_optional=False, verbose=False):

	self.class_var1 = input1_mandatory # mandatory argument, no default specified.
	self.class_var2 = input2_optional # optional argument with a default parameter.
	self.verbose = verbose

	##############
	## Check validity of arguments
	####
	if  ( 	self.templatevarsFileName == "" or self.templatevarsFileName == None or
		self.templateFileName == "" or self.templateFileName == None or
		self.outputFileName == "" or self.outputFileName == None
	):
	    sys.exit("    Note: filenames cannot be an empty string or None:\n" + 
		"     templatevarsFileName="+str(self.templatevarsFileName)+" templateFileName="+\
		str(self.templateFileName)+" outputFileName="+str(self.outputFileName))
	#
	# Check for existence of the files
	if ( not os.path.exists(self.templatevarsFileName) ) :
	    sys.exit("\nERROR: Inputfile '" + self.templatevarsFileName + "' does not exist.\n" + \
		"Terminating program.\n" )
	if ( not os.path.exists(self.templateFileName) ) :
	    sys.exit("\nERROR: Inputfile '" + self.templateFileName + "' does not exist.\n" + \
		"Terminating program.\n" )
	if ( os.path.exists(self.outputFileName) and not self.overwrite ) :
	    sys.exit("\nERROR: Outputfile '" + self.outputFileName + "' already exists.\n" + \
		"Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n")

    def vprint(self, msg=""):
        if(self.verbose): print(msg)

    def run(self):
	##############
	## Section 1 description; typically some kind of initialisation of files
	####
	#self.vprint("Reading variable names and values from file '" + self.templatevarsFileName + "'.")
	#templateVarsFile = open( self.templatevarsFileName, "r" )
	#for line in templateVarsFile:
		#
	#templateVarsFile.close()
				
	##############
	## Section2  description
	####
	# do stuff here


##############
## Command-Line Interface (CLI)
####
if __name__=='__main__':
    import optparse
    class CLI(object):
	usageString = "   usage: %prog -t <templatefile> -o <outputfile> -v <variablesfile> [options]"

	def parse_options(self):
	    parser = optparse.OptionParser(usage=self.usageString)
	    parser.add_option('-t', dest='template',
				help="filename of the template")
	    parser.add_option('-v', dest='varfile',
				help="filename of the variables file")
	    parser.add_option('-o', dest='output',
				help="filename for the output file")
	    parser.add_option("-f", action="store_true", dest="overwrite", default=False,
				help="force overwrite output? [default: %default]")
	    (self.opt, self.args) = parser.parse_args()

	def run(self):
	    self.parse_options()        
	    TemplateSubstitutor(
		template=self.opt.template,
		varfile=self.opt.varfile,
		output=self.opt.output,
		overwrite=self.opt.overwrite,
		verbose=True
	    ).run()

    CLI().run()



# EOF
