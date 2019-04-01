#! /usr/bin/env python
#
# Quick validation script to see whether the generate particle number distribution does indeed satisfy the volume distribution.
#
# Kevin van As
#  June 12th 2015
#
import matplotlib.pyplot as plt
import numpy as np
#
posFileName="test.out"
phiFileName="AartsFig4_vol.dat"
probDensFileName="AartsFig4_probDens.dat"
numBins=20
#
dt = np.dtype([('x',float),('y',float),('z',float)])
data=np.loadtxt(posFileName,dt)
#print data
dataR = np.zeros((np.size(data['x'])))
dataR[:] = np.sqrt(np.square(data['x'])+np.square(data['y']))
dataR = dataR/np.amax(dataR)
hist, bin_edges = np.histogram(dataR,bins=numBins)
bin_centers = np.zeros(np.size(hist))
for i in xrange(0,np.size(bin_centers)) :
    bin_centers[i]=(bin_edges[i]+bin_edges[i+1])/2
print bin_centers,bin_edges, hist
print np.shape(bin_centers), np.shape(bin_edges), np.shape(hist)
#
histVol = hist/bin_centers
histVol = histVol/float(np.amax(histVol))
print hist
#
f1, f2 = plt.figure(), plt.figure()
af1 = f1.add_subplot(111)
af2 = f2.add_subplot(111)
af1.plot(bin_centers,hist,'ro')
af2.plot(bin_centers,histVol,'ro')
af1.set_xlabel('r/R')
af1.set_ylabel('N')
af1.set_title('histogram of particle number for '+str(np.size(dataR))+' particles')
af2.set_xlabel('r/R')
af2.set_ylabel('RBC volume fraction (hematocrit) (normalised)')
af2.set_title('histogram of hematocrit (normalised for fitting)')
plt.draw()
#
####
# Load the probDens-file for comparison, which has two columns: r and phi(r) and convert to [0,1] domain
##
dt = np.dtype([('r',float),('prob',float)])
data=np.loadtxt(probDensFileName,dt)
normFactor=np.amax(data['prob'])/np.amax(hist)
af1.plot(data['r'],data['prob']/normFactor,'b')
####
# Load the phi-file for comparison, which has two columns: r and phi(r) and convert to [0,1] domain
##
dt = np.dtype([('r',float),('phi',float)])
data=np.loadtxt(phiFileName,dt)
data['r']=np.absolute(data['r'])
data = np.sort(data)
R = data['r'][-1]
data['r'] = data['r']/R
data = np.unique(data)
data['phi']=data['phi']/np.amax(data['phi'])
af2.plot(data['r'],data['phi'],'b')
#
f1.savefig('foo1.pdf',bbox_inches='tight')
f2.savefig('foo2.pdf',bbox_inches='tight')
plt.show() # Keep the thread open to view the figures
# EOF
