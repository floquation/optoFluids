#! /usr/bin/env python3
#
# Jorne Boterman
#   ?? ?? ????: plotIntensityAndViewImmediately.py
# Kevin van As
#	17 12 2018: Quick hack to plot intensity to file
#	15 02 2019: Using optoFluidsIO, and cleaner script overall.
# Stephan van Kleef
#	18 02 2019: plt.switch_backend('agg'): No longer needs an X-server to plot.
#

import sys, getopt # Command-Line options
import re # Regular-Expressions
import os.path
import numpy as np # Matrices
import matplotlib

import matplotlib.pyplot as plt
plt.switch_backend('agg') # Then we do not need an X-server to plot.

# Import from optoFluids:
import helpers.regex as myRE
import helpers.nameConventions as names
import helpers.IO as optoFluidsIO


# Command-Line Options
#
intensity2DFN = ""
outputFN = ""
extension = "png"
overwrite = False
pixelCoordsFN = ""
pixelCoords=0
setVMin=None
setVMax=None
noAxis=False
#
usageString = "   usage: " + sys.argv[0] + " -i <intensity2D filename> -o <output filename>" + "[-c <pixelCoords2D file>] [-n minColorValue] [-m maxColorValue] [-f] [-a] \n" \
			  + "	where:\n" \
			  + "	-c: By default tries to locate pixelCoords2D file inside the dir specified at -i" \
			  + "	-a: Do not show title/colorbar"

try:
	opts, args = getopt.getopt(sys.argv[1:],"hfi:o:c:n:m:a")
except getopt.GetoptError:
	print(usageString)
	sys.exit(2)
for opt, arg in opts:
	if opt == '-h':
		print(usageString)
		sys.exit(0)
	elif opt == '-i':
		intensity2DFN = arg
	elif opt == '-o':
		outputFN = arg
	elif opt == '-c':
		pixelCoordsFN = arg
	elif opt == '-n':
		setVMin = float(arg)
	elif opt == '-m':
		setVMax = float(arg)
	elif opt == '-a':
		noAxis = True
	elif opt == '-f':
		overwrite = True
	else :
		print(usageString)
		sys.exit(2)

outputFN = outputFN + "." + extension

if intensity2DFN == "" :
	print(usageString)
	print("    Note: dir-/filenames cannot be an empty string:")
	print("     intensityFileName="+intensity2DFN )
	sys.exit(2)

if outputFN == "" :
	print(usageString)
	print("    Note: dir-/filenames cannot be an empty string:")
	print("     outputFileName="+outputFN )
	sys.exit(2)
elif os.path.exists(outputFN) and not overwrite:
	sys.exit("Outputfile already exists, but overwrite=False. Use -f to overwrite.")

if pixelCoordsFN == "":
	intensity2DDir=os.path.dirname(intensity2DFN)
	print("Checking if 'PixelCoords2D.out' file available in "+intensity2DDir+" or its parent directory.")
	pixelCoordsFN=intensity2DDir+"/PixelCoords2D.out" # In the same directory?
	if(not os.path.isfile(pixelCoordsFN)):
		pixelCoordsFN=intensity2DDir+"/../PixelCoords2D.out" # In the same directory?
		if(not os.path.isfile(pixelCoordsFN)):
			sys.exit("Error, no PixelCoords2D file specified and none found in the usual locations ("+intensity2DDir+"), so cannot continue with the plotting.");

#
###########################
# Algorithm:
##########

# TODO: Call separate module to compute speckle contrast
def computeContrastByLocalContrast(img):
	blockSizeX = 8
	blockSizeY = 8
	C = 0.
	n = 0
	for i in range(0, int(len(img[:,0])/blockSizeX)):
		for j in range(0, int(len(img[0,:])/blockSizeY)):
			localImage = img[i*blockSizeX:(i+1)*blockSizeX-1,j*blockSizeY:(j+1)*blockSizeY-1]
			C += np.std(localImage)/np.mean(localImage)
			n+=1
	return C/float(n)


## Read pixel coordinates
print("Loading pixelCoords2D from ",pixelCoordsFN)
(A,B) = optoFluidsIO.readFromFile_CoordsAB(pixelCoordsFN)
npix=np.shape(A) # first index = a direction, second index = b direction

## Read intensity file
(image, *irrelevant) = optoFluidsIO.readFromFile_Intensity(intensity2DFN, npix)
if(image.ndim != 2):
	sys.exit("Intensityfile \""+str(intensity2DFN)+"\" does not contain 2D data. Cannot plot.")

## Plot figure:
print("Plotting figure " + str(intensity2DFN))
plt.rc('text', usetex=False) # TeXify axis/labels/title
dpi=72.0
if not noAxis:
	fig = plt.figure()
else:
	fig = plt.figure(figsize=(1024/dpi,1024/dpi), dpi=dpi)
plt.pcolormesh(A,B, image, edgecolor='face')#,shading="gouraud")
# Overwrite color range:
if setVMin != None:
	plt.clim(vmin=setVMin)
if setVMax != None:
	plt.clim(vmax=setVMax)
# Axis / Legend / Title:
plt.axis("off")
if not noAxis:
	cb=plt.colorbar()
	cb.set_label(r"$I$ [a.u]")
	plt.title(r"$\langle C \rangle _{window} =$ "+str(computeContrastByLocalContrast(image)))
else:
	plt.subplots_adjust(left=0, right=1.0, top=1.0, bottom=0)
# Output:
fig.savefig(outputFN)

#plt.show(block=True) # to show figure immediately






# EOF
