#! /usr/bin/python

myFile = file( "sillyFile.txt", "r" )
myCopiedFile = file( "fileCopyer_sillyFile_copy.txt", "w" )

for line in myFile:
    myCopiedFile.write( line.rstrip() + "\n" )

myCopiedFile.close()
myFile.close()

# EOF
