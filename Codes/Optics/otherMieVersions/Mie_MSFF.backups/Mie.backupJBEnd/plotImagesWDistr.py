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
	print "Checking if 'pixelCoords2D.out' file available in "+intensity2DDir
	if(os.path.isfile(intensity2DDir+"/pixelCoords2D.out")):
		pixelCoords = np.loadtxt(intensity2DDir+"/pixelCoords2D.out",delimiter=' ', skiprows=2)
		if(len(pixelCoords[0,:]) != 2):
			print "   Warning, pixelCoords file seems to be irregular. Errors are unwaranted."
	else:
		sys.exit("Error, no pixelCoords2D file specified and none found in "+intensity2DDir+", cannot continue with the plotting");
else:
	print "Loading pixelCoords2D from ",pixelCoordsFileName
	if(os.path.isfile(pixelCoordsFileName)):
		pixelCoords = np.loadtxt(pixelCoordsFileName,delimiter=' ', skiprows=2)
		if(len(pixelCoords[0,:]) != 2):
			print "   Warning, pixelCoords file seems to be irregular. Errors are unwaranted."
	else:
		sys.exit("Error, pixelCoords2D file specified as "+pixelCoordsFileName+"does not seem to be a file, cannot continue with the plotting");
	
#
###########################
# Algorithm:
##########

def computeIntensityHistogram(img):
	avg = np.mean(img)
	localImage = img/avg #element-wise division to set range to 0-1
	localImage=localImage.reshape((1,localImage.size))
	nbins=20
	bins,step=np.linspace(0,np.max(localImage),num=nbins,retstep=True) #let's make twenty bins for now
	counts=np.zeros(nbins) #the counts for each bin
	for i in range(0,counts.size-1):
		partOne=np.greater_equal(localImage,bins[i]*np.ones((1,localImage.size)))
		partTwo=np.less_equal(localImage,(bins[i]+step)*np.ones((1,localImage.size)))	
		result=partOne*partTwo
		result=1*result #converts to integers
		counts[i] = result.sum()
	counts = counts/counts.sum() #normalize to make probability distr. like
	return bins, counts, step

def computeContrastByLocalContrast(img):
	blockSizeX = 8
	blockSizeY = 8
	C = 0.
	n = 0
	for i in range(0, len(img[:,0])/blockSizeX):
		for j in range(0, len(img[0,:])/blockSizeY):
			localImage = img[i*blockSizeX:(i+1)*blockSizeX-1,j*blockSizeY:(j+1)*blockSizeY-1]
			C += np.std(localImage)/np.mean(localImage)
			n+=1
	return C/float(n)
			


floatRE=r"[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?"
myRegex = "Intensity2D"#+"_t("+floatRE+")\.out"
intensityFileNameRE = re.compile(myRegex)
npixb = int(pixelCoords[0,0])
npixa = int(pixelCoords[0,1])
X = pixelCoords[1:,0].reshape((npixb,npixa))
Y = pixelCoords[1:,1].reshape((npixb,npixa))
plottedAHist=0
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
			if(not plottedAHist):
				fig2 = plt.figure()
				binsimg, countsimg, step = computeIntensityHistogram(image)
				plt.axis([binsimg[0], binsimg[-1], 0, 1])
				plt.bar(binsimg,countsimg, width=step)
				plt.plot(binsimg, np.exp(-1*binsimg))
				print countsimg.sum()
				plt.title("Occurance histogram for intensity distribution")
				plt.xlabel("bins I/<I>")
				plt.ylabel("estimator for p(I/<I>)")
				plt.savefig(intensity2DDir+"/speckleIntensityHistogram.png", dpi=400)
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
			
			
		
	
