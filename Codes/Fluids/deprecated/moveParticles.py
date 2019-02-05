#! /usr/bin/env python3

import sys
import os.path
import numpy as np
from io import StringIO


class MoveParticles(object):
    """
    MoveParticles takes as input a file with on each line (X Y Z) coordinates of a particle,
    and evolves the z direction of that particle in time according to plug flow or a Poseille (R ^ 2 - r ^ 2) profile.
    Periodic boundary conditions are applied.
    Output is a a file for each timestep with the (X Y Z) coordinates of each particle

    Assumptions:
    Particles move in the z-direction
    X,Y origin is centered around (0,0)

    Usage:
    MoveParticles may be called in another Python file as follows:
    from parentDir.filename import ClassName as mymodule
    MoveParticles(input1_mandatory="a",input2_optional="b").run()
    Or it may be used from the command-line as follows, using the CLI:
    filename.py -a "value1" -b "value2"
    """

    def __init__(self, particlePosFileName: str, outputFolder: str, t_total: float, t_start: float, u: float, n_samples: int,
                 flow_type: str, z_min: float, z_max: float, cyl_radius: float, overwrite, verbose=False):
        """
        Initialize the class and check if input files exist and/or can be overwritten.

        :param particlePosFileName: input file
        :param outputFolder: output folder (with trailing slash)
        :param t_total: total time we want to evolve particles over in seconds
        :param u: average velocity of flow in meters per second
        :param n_samples: amount of samples we want to have
        :param flow_type: "plug" or "pois" flow
        :param z_min: first z-coordinate in mm
        :param z_max: last z-coordinate in mm
        :param cyl_radius: radius of the cylinder in mm
        :param overwrite: overwrite the already existing output files, true or false
        :param verbose: output debug message, true or false
        """


        self.particlePosFileName = particlePosFileName
        self.outputFolder = outputFolder
        self.t_total = float(t_total)
        self.t_start = float(t_start)
        self.u = float(u)
        self.n_samples = int(n_samples)
        self.flow_type = str(flow_type)
        self.z_min = float(z_min)
        self.z_max = float(z_max)
        self.cyl_radius = float(cyl_radius)
        self.overwrite = overwrite
        self.verbose = verbose

        if self.particlePosFileName is None or self.particlePosFileName == "":
            sys.exit("Note: particle positions filename cannot be an empty string or None:\n" + str(locals()))

        if self.outputFolder is None or self.outputFolder == "":
            sys.exit("Note: outputfolder cannot be an empty string or None:\n" + str(locals()))

        if self.t_total is None or self.t_total== "":
            sys.exit("Note: t cannot be an empty string or None:\n" + str(locals()))

        if self.u is None or self.u == "":
            sys.exit("Note: u cannot be an empty string or None:\n" + str(locals()))

        if self.flow_type is None or self.flow_type == "":
            sys.exit("Note: flow type cannot be an empty string or None:\n" + str(locals()))

        # Check for existence of the files
        if not os.path.exists(self.particlePosFileName):
            sys.exit("\nERROR: Inputfile '" + self.particlePosFileName + "' does not exist.\n" +
                     "Terminating program.\n")

        if os.path.exists(self.outputFolder) and not self.overwrite:
            sys.exit("\nERROR: Outputfolder '" + self.outputFolder + "' already exists.\n" +
                     "Terminating program to prevent overwrite. Use the -f option to enforce overwrite.\n")

        # Create directory
        if not os.path.exists(self.outputFolder):
            os.mkdir(outputFolder)

    def vprint(self, msg=""):
        if self.verbose:
            print(msg)

    def run(self):
        # Change inputfile to remove () characters
        particlePosFile = open(self.particlePosFileName)
        particlePosFileData = particlePosFile.read().replace("(", "").replace(")", "").strip()
        # skip_header to skip the first two lines of the input file
        particle_positions = np.genfromtxt(StringIO(particlePosFileData), skip_header=2)
        particlePosFile.close()

        # Set cylinder length, which is only used in Poiseuille flow
        cyl_length = (self.z_max - self.z_min)

        if self.flow_type == "pois":
            # Average velocity of the flow, *3/2 Poiseuille floww, and no correction for plug flow
            u = (3 / 2) * self.u
            profile = self.cyl_radius ** 2 - ((np.square(particle_positions[:, 0])) + (
                np.square(particle_positions[:, 1])))  # Poseuille like = R ^ 2 - r ^ 2
            profile = profile / (self.cyl_radius ** 2)  # Normalize = 1 - (r ^ 2) / (R ^ 2).
        elif self.flow_type == "plug":
            # plug flow
            u = self.u
            profile = 1
        else:
            sys.exit("No flow type specified, should be plug or pois")


        for j in range(0, self.n_samples):
            # new position along movement-axis.
            particles_z = particle_positions[:, 2] + profile * u * (self.t_start + (j * (self.t_total / (self.n_samples - 1)))) #TODO: add t-start
            outputFile = self.outputFolder + "particlePositions_t" + "{:.8f}.txt".format(
                self.t_start + (j * self.t_total / (self.n_samples - 1))) #format well

            f = open(outputFile, "w+")
            f.write(str(len(particle_positions)) + "\n")
            f.write("(\n")

            # apply periodic boundary conditions (we don't want to have an empty artery with no blood cells)
            for k, particle in enumerate(particles_z):
                if particle > self.z_max:
                    particles_z[k] = self.z_min + ((particle - self.z_max) % cyl_length)
                if particle < self.z_min:
                    particles_z[k] = self.z_max - ((self.z_min - particle) % cyl_length)

                f.write("(%0.15f %0.15f %0.15f)\n" % (particle_positions[k, 0], particle_positions[k, 1], particles_z[k]))

            f.write(")")
            f.close()


if __name__ == '__main__':
    import optparse


    class CLI(object):
        """
        Class that will allow to run this program using the command line.
        May be replaced with google/python-fire to avoid code duplication.
        """

        usageString = "usage: %prog -p <positionsfile> -o <outputfolder> [options]"

        def __init__(self):
            self.parser = optparse.OptionParser(usage=self.usageString)
            (self.opt, self.args) = (None, None)

        def parse_options(self):
            self.parser.add_option('-p', dest='particlePosFileName',
                                   help="filename of the particle positions"),
            self.parser.add_option('-o', dest='outputFolder',
                                   help="name of the outputFolder")
            self.parser.add_option('-t', dest='t_total',
                                   help="total duration of the simulation")
            self.parser.add_option('--t_start', dest='t_start',
                                   help="start time of the simulation")
            self.parser.add_option('-u', dest='u',
                                   help="speed of the flow")
            self.parser.add_option('-n', dest='n_samples',
                                   help="number of samples")
            self.parser.add_option('--type', dest='flow_type',
                                   help="flow type, plug or pois")
            self.parser.add_option('--z_min', dest='z_min',
                                   help="first coordinate of cylinder")
            self.parser.add_option('--z_max', dest='z_max',
                                   help="last coordinate of cylinder")
            self.parser.add_option('-R', dest='cyl_radius',
                                   help="radius of cylinder")
            self.parser.add_option("-f", action="store_true", dest="overwrite", default=False,
                                   help="force overwrite output? [default: %default]")
            (self.opt, self.args) = self.parser.parse_args()

        def run(self):
            self.parse_options()
            MoveParticles(
                particlePosFileName=self.opt.particlePosFileName,
                outputFolder=self.opt.outputFolder,
                t_total=self.opt.t_total,
                t_start=self.opt.t_start,
                u=self.opt.u,
                n_samples=self.opt.n_samples,
                flow_type=self.opt.flow_type,
                z_min=self.opt.z_min,
                z_max=self.opt.z_max,
                cyl_radius=self.opt.cyl_radius,
                overwrite=self.opt.overwrite,
                verbose=True
            ).run()


    CLI().run()
