#! /usr/bin/python
#
templateVarsFile = file( "templatevars.txt", "r" )
#
# Make a variable dictionary
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
        print "line " + str(i_line) + ": " + "varname="+varname, "varval="+varval
        # Write the dictionary entry
        varDict[ varname ] = varval
    #else: there is no equals sign in this line. raise a warning and ignore the line
    else:
        print "Warning: No equals sign in line " + str(i_line) +": '" + line.rstrip() + "'"
#
templateVarsFile.close()
print "dictionary = " + str(varDict)
#
# Perform the substitution
templateFile = file( "template.txt", "r" )
targetFile = file( "template_substituted.txt", "w" )
for line in templateFile:
    # For each variable, see if it is present in the templateline: `line'
    for item in varDict:
        line = line.replace("$"+item+"$", varDict[item])
    # Replace escape characters:
    line = line.replace("\$","$")
    #line = line.replace("\\\\","\\")
    # Write the substituted line, `line', to the target file
    targetFile.write( line )
targetFile.close()
templateFile.close()
#
#
#
# EOF
