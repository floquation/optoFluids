#! /usr/bin/env python
# 
# phi2probdens.py
#  Kevin van As
#  11th June 2015
#
# Takes a CYLINDRICAL volume fraction (hematocrit) (V_RBC/V_tot), phi(r)
#  and converts it to a number probability density function and an accumulate probability density function.
#  The latter may be used to insert particles into a cylindrical geometry with the correct distribution.
#
# Rules:
# - The phi data-set cannot have conflicting values. I.e., a different value for phi for the same r.
# - It should include the r=0 point.
# - It should include the r=R_max point (I suppose with a guaranteed zero probability?)
#
# Usage:
#  phi2probdens.py -h 
#  phi2probdens.py -i fig4.dat -o fig4 
#
import re # Regular-Expressions
import sys, getopt # Command-Line options
import os.path, inspect
import subprocess # Execute another python program
from shutil import copyfile, rmtree
import numpy as np # Matrices
from scipy import integrate # Science operations
#
import matplotlib.pyplot as plt
#
filename = inspect.getframeinfo(inspect.currentframe()).filename
scriptDir = os.path.dirname(os.path.abspath(filename))
#
# Command-Line Options
#
phiFileName = ""
outputFileNameBase = ""
outputFileName1 = ""
outputFileName2 = ""
overwrite = False
showGraphs = False
#
usageString = "   usage: " + sys.argv[0] + " -i <phi fileName> [-o <BASE output fileName (no extension)>]\n" \
            + "     where:\n" \
            + "       -f := force overwrite. WARNING: This will remove any existing directory specified using the -o option\n" \
            + "       -d := showGraphs\n"
try:
    opts, args = getopt.getopt(sys.argv[1:],"hdfi:o:")
except getopt.GetoptError:
    print usageString 
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        print usageString 
        sys.exit(0)
    elif opt == '-i':
        phiFileName = arg
    elif opt == '-o':
        outputFileNameBase = arg
        outputFileName1 = outputFileNameBase+"_probDens.dat"
        outputFileName2 = outputFileNameBase+"_probAccum.dat"
    elif opt == '-f':
        overwrite = True
    elif opt == '-d':
        showGraphs = True
    else :
        print usageString 
        sys.exit(2)
#
if outputFileNameBase == "" :
    outputFileName1 = "probDens.dat"
    outputFileName2 = "probAccum.dat"
if phiFileName == "" :
    print usageString 
    print "    Note: dir-/filenames cannot be an empty string:"
    print "     phiFileName="+phiFileName+" outputFileName1="+outputFileName1+" outputFileName2="+outputFileName2
    sys.exit(2)
#
# Check for existence of the files
if not os.path.exists(phiFileName) or not os.path.isfile(phiFileName) :
    print "\nERROR: phiFile '"+phiFileName+"' (-i) must exist and be a file."
    print usageString 
    sys.exit(2)
if ( os.path.exists(outputFileName1) and not overwrite ) :
    sys.exit("\nERROR: OutputFile '" + outputFileName1 + "' already exists.\n" + \
             "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n" + \
             "BE WARNED: This will remove the existing OutputFile!")
if ( os.path.exists(outputFileName2) and not overwrite ) :
    sys.exit("\nERROR: OutputFile '" + outputFileName2 + "' already exists.\n" + \
             "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n" + \
             "BE WARNED: This will remove the existing OutputFile!")
#
if ( os.path.exists(outputFileName1) and overwrite ) :
    if os.path.isdir(outputFileName1) :
        rmtree(outputFileName1)
    else :
        os.remove(outputFileName1)
if ( os.path.exists(outputFileName2) and overwrite ) :
    if os.path.isdir(outputFileName2) :
        rmtree(outputFileName2)
    else :
        os.remove(outputFileName2)
#
#####
# Convert phi=V/V to a number probability density function
##
# 1) Load the phi-file, which has two columns: r and phi(r) and convert to [0,1] domain
dt = np.dtype([('r',float),('phi',float)])
data=np.loadtxt(phiFileName,dt)
#print "data=", data
data['r']=np.absolute(data['r'])
#print "data.abs=", data
data = np.sort(data)
#print "data.sorted=", data
R = data['r'][-1]
#print "R=", R
data['r'] = data['r']/R
#print "data.normalised=", data
data = np.unique(data)
#print "data.unique=", data
#print "x*y=", data['phi']*data['r']
#I = integrate.simps(data['phi'],data['r']) # Check if simps works as expected
#print "I = ", I
# 2) Compute the probability density function
prob=data['phi']*data['r'] # Unnormalised "probability density function"
I = integrate.simps(prob,data['r'])
#print "I = ", I
prob=prob/I # Normalised probability density function
#print "prob=", prob
# 3) Compute the accumulated probability density function
cumprob=integrate.cumtrapz(prob,data['r'], initial=0) # It is ensured to start with 0
print "integration error made cumprob[-1] = ", cumprob[-1], ", which should be 1. Normalising."
cumprob=cumprob/cumprob[-1] # Ensure it ends with 1
#print "size cumprob=", np.size(cumprob), "; size r=", np.size(data['r'])
#
if showGraphs :
    f1, f2 = plt.figure(), plt.figure()
    af1 = f1.add_subplot(111)
    af2 = f2.add_subplot(111)
    af1.plot(data['r'],data['phi'],'ro')
    af1.plot(data['r'],data['phi']*data['r'],'bo')
    af2.plot(data['r'],prob,'ro')
    af2.plot(data['r'],cumprob,'bo')
    plt.draw()
#
#prob    =   prob.reshape        (1,prob.shape[0])
#prob_r  =   data['r']
#prob_r  =   prob_r.reshape      (1,prob_r.shape[0])
#prob_tuple = (prob_r,prob)
#print "shape(prob_tuple)=", np.shape(prob_tuple)
#prob_tuple = prob_tuple.reshape(prob_tuple.shape[1],prob_tuple.shape[0])
#print "shape(prob)=", np.shape(prob)
#print "shape(r)=", np.shape(data['r'])
#print "shape(prob_r)=", np.shape(prob_r)
#print "shape(prob_tuple)=", np.shape(prob_tuple)
# 4) Write to file
np.savetxt(outputFileName1,np.c_[data['r'],prob])
np.savetxt(outputFileName2,np.c_[data['r'],cumprob])
#
if showGraphs :
    plt.show()
#
#print "Done."
# EOF
