#! /usr/bin/python

myFile = file( "sillyFile.txt", "r" )

for line in myFile:
    print line,

myFile.close()

# EOF
