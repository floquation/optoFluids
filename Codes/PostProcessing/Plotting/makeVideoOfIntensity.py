#! /usr/bin/python3
# TODO: Unfinished script.
# Instead, we currently write many images to file, then sort them by frame, and then use Blender to convert an image sequence into a video.

#
#
#

import sys, getopt # Command-Line options
import re # Regular-Expressions
import os.path
import numpy as np # Matrices
import cv2 # Video processing
#import matplotlib
#import matplotlib.pyplot as plt

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
		sys.exit("Error, no pixelCoords2D file specified and none found in "+intensity2DDir+", cannot continue with the plotting");
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
for intensity2DFileName in os.listdir(intensity2DDir):
	r = intensityFileNameRE.search(intensity2DFileName)
	if r: #Filter files using regex
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
			
			
def imagesToVideo():
	#TODO: Make parameters
	ext=png
	dir_path="."
	FPS=20.0

	# Find image filenames
	images = []
	for f in os.listdir(dir_path):
	    if f.endswith(ext):
	        images.append(f)
	
	# Determine the width and height from the first image
	image_path = os.path.join(dir_path, images[0])
	frame = cv2.imread(image_path)
	cv2.imshow('video',frame)
	height, width, channels = frame.shape
	
	# Define the codec and create VideoWriter object
	fourcc = cv2.VideoWriter_fourcc(*'mp4v') # Be sure to use lower case
	out = cv2.VideoWriter(output, fourcc, FPS, (width, height))
	
	for image in images:
	    image_path = os.path.join(dir_path, image)
	    frame = cv2.imread(image_path)
	    out.write(frame) # Write out frame to video
	
	    cv2.imshow('video',frame)
	    if (cv2.waitKey(1) & 0xFF) == ord('q'): # Hit `q` to exit
	        break
	
	# Release everything if job is finished
	out.release()
	cv2.destroyAllWindows()

		
	
