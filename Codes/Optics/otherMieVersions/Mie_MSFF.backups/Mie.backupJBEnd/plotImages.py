#! /net/users/jboterman/Applications/Anaconda/bin/python
import sys, getopt # Command-Line options
import re # Regular-Expressions
import os.path
import numpy as np # Matrices
import matplotlib.pyplot as plt
# This puppy creates an image of the same name for each .out file in the inputfolder

# Command-Line Options
#
intensity2DDir = ""
pixelCoordsFileName = ""
pixelCoords=0
#
usageString = "   usage: " + sys.argv[0] + " -i <intensity2D dir>" + "[-c <pixelCoords2D file>]\n" \
		+ "	where:\n"\
		+ "	-c: By default tries to locate pixelCoords2D file inside the dir specified at -i"

try:
    opts, args = getopt.getopt(sys.argv[1:],"hfli:o:t:c:")
except getopt.GetoptError:
    print usageString 
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        print usageString 
        sys.exit(0)
    elif opt == '-i':
        intensity2DDir = arg
    elif opt == '-c':
	pixelCoordsFileName = arg
    else :
        print usageString 
        sys.exit(2)

if intensity2DDir == "" :
    print usageString 
    print "    Note: dir-/filenames cannot be an empty string:"
    print "     intensityDirName="+intensity2DDir 
    sys.exit(2)

if pixelCoordsFileName == "":
	print "Checking if 'PixelCoords2D.out' file available in "+intensity2DDir
	if(os.path.isfile(intensity2DDir+"/PixelCoords2D.out")):
		pixelCoords = np.loadtxt(intensity2DDir+"/PixelCoords2D.out",delimiter=' ', skiprows=2)
		if(len(pixelCoords[0,:]) != 2):
			print "   Warning, PixelCoords file seems to be irregular. Errors are unwaranted."
	else:
		sys.exit("Error, no PixelCoords2D file specified and none found in "+intensity2DDir+", cannot continue with the plotting");
else:
	print "Loading PixelCoords2D from ",pixelCoordsFileName
	if(os.path.isfile(pixelCoordsFileName)):
		pixelCoords = np.loadtxt(pixelCoordsFileName,delimiter=' ', skiprows=2)
		if(len(pixelCoords[0,:]) != 2):
			print "   Warning, PixelCoords file seems to be irregular. Errors are unwaranted."
	else:
		sys.exit("Error, PixelCoords2D file specified as "+pixelCoordsFileName+"does not seem to be a file, cannot continue with the plotting");
	
#
###########################
# Algorithm:
##########

def computeContrastByLocalContrast(img):
	#For the blocksize enter something like 10d_speckle where d_speckle can be estimated as lambda*z/L, where L is the max inter particle distance (length of tube)
	#When speckle is totally unresolved, use d_speckle = 1, since we are now promoting each pixel to be a speckle really
	blockSizeX = 128
	blockSizeY = 128
	C = 0.
	n = 0
	for i in range(0, len(img[:,0])/blockSizeX):
		for j in range(0, len(img[0,:])/blockSizeY):
			localImage = img[i*blockSizeX:(i+1)*blockSizeX-1,j*blockSizeY:(j+1)*blockSizeY-1]
			C += np.std(localImage)/np.mean(localImage)
			n+=1
	return C/float(n)
			

myRegex = "Intensity2D.*\.out"
intensityFileNameRE = re.compile(myRegex)
npixb = int(pixelCoords[0,0])
npixa = int(pixelCoords[0,1])
X = pixelCoords[1:,0].reshape((npixb,npixa))
Y = pixelCoords[1:,1].reshape((npixb,npixa))

for intensity2DFileName in os.listdir(intensity2DDir):
	r = intensityFileNameRE.search(intensity2DFileName)
	if r: #Filter files using regex
		image = np.loadtxt(intensity2DDir+"/"+intensity2DFileName)
		if(image.ndim != 2):
			print "This intensity2D file did not contain 2D information somehow. Use your panzerschreck to destroy this half-track\n"
			print "Nah but seriously, this file "+intensity2DFileName+" is skipped."
		else: #have correct dimensions at least, let's plot these bitches
			fig = plt.figure()
			plt.pcolormesh(X,Y, image)#,shading="gouraud")
			plt.colorbar()
			plt.title("<C_local>_blocks = "+str(computeContrastByLocalContrast(image)))
			plt.savefig(intensity2DDir+"/"+intensity2DFileName[:-4]+".png", dpi=400)
			plt.close(fig)
			#The plots below will show the intensity distribution.. but not really important anyhowzers.
			#fig2 = plt.figure()
			#plt.plot(np.linspace(1,128,128),np.mean(image,axis=1)/np.max(np.mean(image,axis=1))) #the mean along direction a as a function thus of b
			#plt.savefig(intensity2DDir+"/"+intensity2DFileName[:-4]+"<I>a(b).png")
			#plt.close(fig2)
			#fig3 = plt.figure()
			#plt.plot(np.linspace(1,128,128),np.mean(image,axis=0)/np.max(np.mean(image,axis=0))) #the mean along direction a as a function thus of b
			#plt.savefig(intensity2DDir+"/"+intensity2DFileName[:-4]+"<I>b(a).png")
			#plt.close(fig3)

sys.exit("Done")
			
			
		
	
