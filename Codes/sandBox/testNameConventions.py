#! /usr/bin/env python3

import re
import helpers.nameConventions as names
import helpers.regex as myRE

print(names.particlePostitionsFNRE)
print(myRE.getMatch("pos_t0.01",re.compile(names.particlePostitionsFNRE)))
print(myRE.getMatch("posi_t0.01",re.compile(names.particlePostitionsFNRE)))
print(myRE.getMatch("particlePosition_t0.01",re.compile(names.particlePostitionsFNRE)))
print(myRE.getMatch("particlePositions_t0.01",re.compile(names.particlePostitionsFNRE)))
print(myRE.getMatch("pos_t0.01.out",re.compile(names.particlePostitionsFNRE)))
print(myRE.getMatch("pos_t5_0.01.out",re.compile(names.particlePostitionsFNRE)))

print()

print(myRE.getMatch("Intensity_t0.01",re.compile(names.intensityFNRE)))
print(myRE.getMatch("Intensity_t0.01",re.compile(names.intensity1DFNRE)))
print(myRE.getMatch("Intensity_t0.01",re.compile(names.intensity2DFNRE)))
print(myRE.getMatch("intensity_t0.01",re.compile(names.intensityFNRE)))
print(myRE.getMatch("Intensity2D_t0.01",re.compile(names.intensityFNRE)))
print(myRE.getMatch("Intensity2D_t0.01",re.compile(names.intensity1DFNRE)))
print(myRE.getMatch("Intensity2D_t0.01",re.compile(names.intensity2DFNRE)))

print()

print(names.intensity2DFN(6.0))
print(names.intensity2DFN(2e-10,2))
print(names.logFN(-2.5))
print(myRE.getMatch(names.logFN(-2.5,logDir=""),re.compile(names.logFNRE)))

