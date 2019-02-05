#! /usr/bin/env python3
#
# This script takes a template_variables (-v) file in which variables are defined (and interprets them as strings).
#  It then substitutes those variables in the specified template (-t) file, which has variables in the form $varName$.
#  The result is written to the file specified with the -o option.
#
# Kevin van As
#	17 06 2015: Original
#	07 09 2018: Converted to CLI/Class structure. Converted to Python3.
#   10 09 2018: Added verbose printing (vprint)
#   14 09 2018: No longer terminate when matching variable is not found,
#				such that templateSubstitutor may be used recursively for
#				multiple templateVars files.
#

import re
import sys
import os.path

##############
## Worker class
####
class TemplateSubstitutor(object):
	#templatevarsFileName = ""
	#templateFileName = ""
	#outputFileName = ""
	#overwrite = False
	#verbose = False
    
	def __init__(self, template, varfile, output, overwrite=False, verbose=False):

		self.templateFileName = template
		self.templatevarsFileName = varfile
		self.outputFileName = output
		self.overwrite = overwrite
		self.verbose = verbose

		##############
		## Check validity of arguments
		####
		if	( 	self.templatevarsFileName == "" or self.templatevarsFileName == None or
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
		## Make a variable dictionary
		####
		self.vprint("Reading variable names and values from file '" + self.templatevarsFileName + "'.")
		templateVarsFile = open( self.templatevarsFileName, "r" )
		varDict = dict()
		i_line = 0
		for line in templateVarsFile:
			i_line+=1
			# Ignore comments (first character = `!')
			if line[0] == "!" :
				continue
			# Find the equals sign
			if "=" in line :
				indexEq=line.index( "=" )
				varname=line[0:indexEq].rstrip().lstrip()
				varval=line[indexEq+1:len(line)].rstrip().lstrip()
#        print("line " + str(i_line) + ": " + "name="+varname, "value="+varval)
				# Write the dictionary entry
				varDict[ varname ] = varval
			#else: there is no equals sign in this line. raise a warning and ignore the line
			elif len(line.rstrip())>0:
				self.vprint("  WARNING: No equals sign in line " + str(i_line) +": '" + line.rstrip() + "' -> " \
					"The line is ignored.")
		#
		templateVarsFile.close()
		self.vprint("  dictionary = " + str(varDict))
		
		##############
		## Perform the substitutions
		####
		self.vprint("Performing the substitution using the template '" + self.templateFileName + \
			 "' and writing to '" + self.outputFileName + "'.")
		templateFile = open( self.templateFileName, "r" )
		targetFile = open( self.outputFileName, "w" )
		i_line = 0
		for line in templateFile:
			i_line+=1
			# Ignore comments
			if line[0] == "!" :
				#print("line_old = " + str([line]) + "\n Ignoring line.")
				continue
				#print("'" + line[0:2] + "'")
			if line[0:2] == "\\!" : # Escape
				line = line[1:len(line)] # Remove the first character from the line, which is a '\'.
			# Scan the line from left to right to find starting-$ and closing-$, with the exception of `\$':
			# Ignore `\$':
			lineSplit = re.split("\\\\\\$",line) # Escape three slashes in Python. Escape one slash and the dollar sign in regex. Result is '\$'. Yes really.
			#print(lineSplit)
			line_new=""
			for spl in lineSplit :
				# Now split on `$', such that all even-indices of `lineSplit2' are inside a matching pair of $'s.
				lineSplit2 = re.split("\\$",spl)
				spl_new=""
				#print(lineSplit2)
				#print(len(lineSplit2))
				# If there is an even number of elements in lineSplit2, then there is a $-mismatch. Raise a fatal error.
				if (len(lineSplit2)%2 == 0) :
					sys.exit("ERROR. $-sign mismatch at line " + str(i_line) + ": '" + \
						line.rstrip() + "'.\nPROGRAM WILL NOW TERMINATE")            
				# Compare the variableNames in the template with those in the dictionary and substitute.
				for i_varname in range(1,len(lineSplit2),2) :
					spl_new=spl_new+lineSplit2[i_varname-1] 
					matched=False
					for item in varDict :
						if (item == lineSplit2[i_varname]) :
							matched=True
							self.vprint("matching variable: " + item)
							break
					if (not matched) :
						print("WARNING: Unknown variable name at line " + str(i_line) + ": '" + lineSplit2[i_varname] + "'.\n")
						#sys.exit("ERROR: Unknown variable name at line " + str(i_line) + ": '" + lineSplit2[i_varname] + "'.\n" + \
						#	"PROGRAM WILL NOW TERMINATE")
						spl_new=spl_new+"$"+lineSplit2[i_varname]+"$" # Concatenate the spline without substitution
					else:
						spl_new=spl_new+varDict[lineSplit2[i_varname]] # Concatenate the spline with substitution
				spl_new=spl_new+lineSplit2[-1] # Concatenate the spline
				#print("spl_new = " + str([spl_new]))
				line_new=line_new+"$"+spl_new # Concatenate the line
			line_new=line_new[1:len(line_new)] # Take out the first accidental $-sign.
			#print("line_old = " + str([line]))
			#print("line_new = " + str([line_new]))
			#        
			# Write the substituted line, `line_new', to the target file
			targetFile.write( line_new )
		targetFile.close()
		templateFile.close()
		#
		#print("Program terminated successfully.")
		#



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
			parser.add_option("--verbose", action="store_true", dest="verbose", default=False,
								help="Print info messages? [default: %default]")
			(self.opt, self.args) = parser.parse_args()

		def run(self):
			self.parse_options()        
			TemplateSubstitutor(
				template=self.opt.template,
				varfile=self.opt.varfile,
				output=self.opt.output,
				overwrite=self.opt.overwrite,
				verbose=self.opt.verbose
			).run()

	CLI().run()



# EOF
