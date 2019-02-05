#! /usr/bin/env python3

# TODO: Plot single file function
# TODO: Save to file

import sys, getopt # Command-Line options
import re # Regular-Expressions
import os.path
import numpy as np # Matrices
import matplotlib

import matplotlib.pyplot as plt

# Import from optoFluids:
import helpers.regex as myRE
import helpers.nameConventions as names


# This puppy creates an image of the same name for each .out file in the inputfolder

# Command-Line Options
#
intensity2DDir = ""
pixelCoordsFileName = ""
pixelCoords=0
filenummer = 1
#
usageString = "   usage: " + sys.argv[0] + " -i <intensity2D dir>" + "[-c <pixelCoords2D file>]"+"[-n filenumberToPlot]\n" \
			  + "	where:\n" \
			  + "	-c: By default tries to locate pixelCoords2D file inside the dir specified at -i"

try:
	opts, args = getopt.getopt(sys.argv[1:],"hfli:o:t:c:n:")
except getopt.GetoptError:
	print(usageString)
	sys.exit(2)
for opt, arg in opts:
	if opt == '-h':
		print(usageString)
		sys.exit(0)
	elif opt == '-i':
		intensity2DDir = arg
	elif opt == '-c':
		pixelCoordsFileName = arg
	elif opt == '-n':
		filenummer = int(arg)
	else :
		print(usageString)
		sys.exit(2)

if intensity2DDir == "" :
	print(usageString)
	print("    Note: dir-/filenames cannot be an empty string:")
	print("     intensityDirName="+intensity2DDir )
	sys.exit(2)

if pixelCoordsFileName == "":
	print("Checking if 'pixelCoords2D.out' file available in "+intensity2DDir)
	if(os.path.isfile(intensity2DDir+"/PixelCoords.out")):
		pixelCoords = np.loadtxt(intensity2DDir+"/PixelCoords.out",delimiter=' ', skiprows=2)
		if(len(pixelCoords[0,:]) != 2):
			print("   Warning, pixelCoords file seems to be irregular. Errors are unwaranted.")
	else:
		sys.exit("Error, no PixelCoords2D file specified and none found in "+intensity2DDir+", cannot continue with the plotting");
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
intensityFNRO = re.compile(names.intensityFNRE)
intensityFiles = myRE.getMatchingItemsAndGroups(os.listdir(intensity2DDir), intensityFNRO)
for intensity2DFileName, time in intensityFiles:
	teller += 1
	if(teller == filenummer):
		image = np.loadtxt(intensity2DDir+"/"+intensity2DFileName)
		if(image.ndim != 2):
			print("This intensity2D file did not contain 2D information somehow. Use your panzerschreck to destroy this half-track\n")
			print("Nah but seriously, this file "+intensity2DFileName+" is skipped.")
		else: #have correct dimensions at least, let's plot these bitches
			print("Plotting figure " + intensity2DFileName)
			fig = plt.figure()
			plt.pcolormesh(X,Y, image, edgecolor='face')#,shading="gouraud")
			plt.axis("off")
			cb=plt.colorbar()
			cb.set_label(r"$I$ [a.u]")
			plt.title(r"$\langle C \rangle _{window} =$ "+str(computeContrastByLocalContrast(image)))

plt.show(block=True)
sys.exit("Done")
			
			
		
	
