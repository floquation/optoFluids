#! /usr/bin/python
#
import re
import sys, getopt
import os.path
#
# Parse command-line options:
#
#templatevarsFileName = "templatevars.txt"
#templateFileName = "template2.txt"
#outputFileName = "template2_substituted.txt"
templatevarsFileName = ""
templateFileName = ""
outputFileName = ""
overwrite = False
#
usageString = "   usage: " + sys.argv[0] + " -t <templatefile> -o <outputfile> -v <variablesfile> " \
            + "[-f]\n" \
            + "          -f := Force overwrite"
try:
    opts, args = getopt.getopt(sys.argv[1:],"hfv:t:o:")
except getopt.GetoptError:
    print usageString 
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        print usageString 
        sys.exit(0)
    elif opt == '-t':
        templateFileName = arg
    elif opt == '-v':
        templatevarsFileName = arg
    elif opt == '-o':
        outputFileName = arg
    elif opt == '-f':
        overwrite = True
    else :
        print usageString 
        sys.exit(2)
#
if templatevarsFileName == "" or templateFileName == "" or outputFileName == "" :
        print usageString 
        print "    Note: filenames cannot be an empty string:"
        print "     templatevarsFileName="+templatevarsFileName+" templateFileName="+\
                    templateFileName+" outputFileName="+outputFileName 
        sys.exit(2)
#
# Check for existence of the files
if ( not os.path.exists(templatevarsFileName) ) :
    sys.exit("\nERROR: Inputfile '" + templatevarsFileName + "' does not exist.\n" + \
             "Terminating program.\n" )
if ( not os.path.exists(templateFileName) ) :
    sys.exit("\nERROR: Inputfile '" + templateFileName + "' does not exist.\n" + \
             "Terminating program.\n" )
if ( os.path.exists(outputFileName) and not overwrite ) :
    sys.exit("\nERROR: Outputfile '" + outputFileName + "' already exists.\n" + \
             "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n")
#
###############################
# Make a variable dictionary
print "\nReading variable names and values from file '" + templatevarsFileName + "'.\n"
templateVarsFile = file( templatevarsFileName, "r" )
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
        varval=line[indexEq+1:len(line)-1].rstrip().lstrip()
        print "line " + str(i_line) + ": " + "name="+varname, "value="+varval
        # Write the dictionary entry
        varDict[ varname ] = varval
    #else: there is no equals sign in this line. raise a warning and ignore the line
    else:
        print "WARNING: No equals sign in line " + str(i_line) +": '" + line.rstrip() + "' -> " \
         "The line is ignored."
#
templateVarsFile.close()
print "dictionary = " + str(varDict)
#
# Perform the substitutions
print "\nPerforming the substitution using the template '" + templateFileName + \
 "' and writing to '" + outputFileName + "'.\n"
templateFile = file( templateFileName, "r" )
targetFile = file( outputFileName, "w" )
i_line = 0
for line in templateFile:
    i_line+=1
    # Ignore comments
    if line[0] == "!" :
        print "line_old = " + str([line]) + "\n Ignoring line."
        continue
#    print "'" + line[0:2] + "'"
    if line[0:2] == "\\!" : # Escape
        line = line[1:len(line)]
    # Scan the line from left to right to find starting-$ and closing-$, with the exception of `\$':
    # Ignore `\$':
    lineSplit = re.split("\\\\\\$",line)
#    print lineSplit
    line_new=""
    for spl in lineSplit :
        # Now split on `$', such that all even-indices of `lineSplit2' are inside a matching pair of $'s.
        lineSplit2 = re.split("\\$",spl)
        spl_new=""
#        print lineSplit2
#        print len(lineSplit2)
        # If there is an even number of elements in lineSplit2, then there is a $-mismatch. Raise a fatal error.
        if (len(lineSplit2)%2 == 0) :
            sys.exit("ERROR. $-sign mismatch at line " + str(i_line) + ": '" + \
             line.rstrip() + "'.\nPROGRAM WILL NOW TERMINATE")            
        # Compare the variableNames in the template with those in the dictionary and substitute.
        for i_varname in xrange(1,len(lineSplit2),2) :
            spl_new=spl_new+lineSplit2[i_varname-1] 
            matched=False
            for item in varDict :
                if (item == lineSplit2[i_varname]) :
                    matched=True
#                    print "matching variable: " + item
            if (not matched) :
                sys.exit("ERROR: Unknown variable name at line " + str(i_line) + ": '" + lineSplit2[i_varname] + "'.\n" + \
                 "PROGRAM WILL NOW TERMINATE")
            spl_new=spl_new+varDict[lineSplit2[i_varname]] # Concatenate the spline
        spl_new=spl_new+lineSplit2[-1] # Concatenate the spline
#        print "spl_new = " + str([spl_new])
        line_new=line_new+"$"+spl_new # Concatenate the line
    line_new=line_new[1:len(line_new)] # Take out the first accidental $-sign.
    print "line_old = " + str([line])
    print "line_new = " + str([line_new])
#        
    # Write the substituted line, `line_new', to the target file
    targetFile.write( line_new )
targetFile.close()
templateFile.close()
#
print "\nProgram terminated successfully."
#
# EOF
