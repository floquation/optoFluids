#! /usr/bin/env python3
#
# Jorne Boterman
#   ?? ?? ????: plotIntensityAndViewImmediately.py
# Kevin van As
#	17 12 2018: Quick hack to plot intensity to file
#

import sys, getopt # Command-Line options
import re # Regular-Expressions
import os.path
import numpy as np # Matrices
import matplotlib

import matplotlib.pyplot as plt

# Import from optoFluids:
import helpers.regex as myRE
import helpers.nameConventions as names


# Command-Line Options
#
intensity2DFN = ""
outputFN = ""
extension = "png"
overwrite = False
pixelCoordsFileName = ""
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
		pixelCoordsFileName = arg
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

if pixelCoordsFileName == "":
	print("Checking if 'pixelCoords2D.out' file available in "+intensity2DFN)
	if(os.path.isfile(intensity2DFN+"/PixelCoords.out")):
		pixelCoords = np.loadtxt(intensity2DFN+"/PixelCoords.out",delimiter=' ', skiprows=2)
		if(len(pixelCoords[0,:]) != 2):
			print("   Warning, pixelCoords file seems to be irregular. Errors are unwaranted.")
	else:
		sys.exit("Error, no PixelCoords2D file specified and none found in "+intensity2DFN+", cannot continue with the plotting");
else:
	print("Loading pixelCoords2D from ",pixelCoordsFileName)
	if(os.path.isfile(pixelCoordsFileName)):
		pixelCoords = np.loadtxt(pixelCoordsFileName,delimiter=' ', skiprows=2)
		if(len(pixelCoords[0,:]) != 2):
			print("   Warning, pixelCoords file seems to be irregular. Errors are unwaranted.")
	else:
		sys.exit("Error, pixelCoords2D file specified as "+pixelCoordsFileName+"does not seem to be a file, cannot continue with the plotting");

#
###########################
# Algorithm:
##########

plt.rc('text', usetex=False) #Let's TeXify the labels and what not

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



floatRE=r"[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?"
myRegex = "Intensity2D_t("+floatRE+")\.out"
intensityFileNameRE = re.compile(myRegex)
npixa = int(pixelCoords[0,0])
npixb = int(pixelCoords[0,1])
X = pixelCoords[1:,0].reshape((npixb,npixa))
Y = pixelCoords[1:,1].reshape((npixb,npixa))
X = X.T
Y = Y.T

teller = 0
intensityFNRO = re.compile(names.intensity2DFNRE)
#print(names.intensity2DFNRE)
#print(intensity2DFN)

#intensityFiles = myRE.getMatchingItemsAndGroups(os.listdir(intensity2DFN), intensityFNRO)

if myRE.doesItemMatch(names.basename(intensity2DFN),intensityFNRO):
	image = np.loadtxt(intensity2DFN)
	if(image.ndim != 2):
		print("This intensity2D file did not contain 2D information somehow. Use your panzerschreck to destroy this half-track\n")
		print("Nah but seriously, this file "+str(intensity2DFN)+" is skipped.")
	else: #have correct dimensions at least, let's plot these bitches
		# Plot figure:
		print("Plotting figure " + str(intensity2DFN))
		dpi=72.0
		if not noAxis:
			fig = plt.figure()
		else:
			fig = plt.figure(figsize=(1024/dpi,1024/dpi), dpi=dpi)
		plt.pcolormesh(X,Y, image, edgecolor='face')#,shading="gouraud")
		# Overwrite color range:
		if setVMin != None:
			plt.clim(vmin=setVMin)
		if setVMax != None:
			plt.clim(vmax=setVMax)
		# Axis / Legend:
		plt.axis("off")
		if not noAxis:
			cb=plt.colorbar()
			cb.set_label(r"$I$ [a.u]")
			plt.title(r"$\langle C \rangle _{window} =$ "+str(computeContrastByLocalContrast(image)))
		else:
			plt.subplots_adjust(left=0, right=1.0, top=1.0, bottom=0)
		# Output:
		fig.savefig(outputFN)
		plt.close(fig) # TODO: Needed?
else:
	sys.exit("Inputfile '" + str(intensity2DFN) + "' is not an intensity2D file")


#plt.show(block=True)
#sys.exit("Done")








# EOF
