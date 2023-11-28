This example shows a full optoFluids case directory, using OpenFOAM for the Computational Fluid Dynamics (CFD) simulation.
A case directory such as this was used for our 2022 atherosclerosis paper:
Van As, K., Dellevoet, S. F. L. J., Boterman, J., Kleijn, C. R., Bhattacharya, N., & Kenjeres, S. (2022). Toward detecting atherosclerosis using dynamic laser speckle contrast imaging: A numerical study. Journal of Applied Physics, 131(18).



==== Choosing which OpenFOAM simulation to run ====

Within the fluids folder, there are four cases:
- base (cylindrical geometry) (serial execution)
- base_parallel (cylindrical geometry) (parallel execution)
- CarotidArtery_serial (serial execution)
- CarotidArtery_parallel (parallel execution)

To select a case, do the following:
1) In the root folder's runAll.sh, change the variable named 'fluids_case' to the name of the basefolder (e.g., 'base' or 'CarotidArtery_serial').
2) In the fluids folder's runAll.sh, uncomment the line that executes the desired case (and comment the others).




==== Files ====

Before you start doing anything, make sure the modules are loaded by typing
$ loadoptofluids

== Root optoFluids case directory ==
- runAll.sh is the main script. This script calls all other scripts to perform a full optoFluids simulations: fluids -> coupling -> optics.
- input_time is a datafile that is sourced by scripts in the fluids and optics folders. These variables are the overarching variables, shared between fluids and optics.
- cleanAll.sh removes ALL generated files. Don't use that on your data. ;-)

== Fluids ==
- runAll.sh executes runFoam.sh with its required parameters. Use this file to select which OpenFOAM case you'd like to run. runAll.sh is called by ../runAll.sh automatically.
- runFoam.sh is the big script that does the heavy lifting (see below)
- makeJobFile.sh is an intermediate step between runAll.sh and runFoam.sh. It produces the file 'jobfile.pbs' from 'jobfile.pbs.tmplt'. This jobfile can be executed on a High-Performance Cluster (HPC). It is automatically submitted by the runAll.sh script with the 'qsub jobfile.pbs' command.
- cleanAll.sh clears the template, removing all generated files. Don't use that on your data. ;-)
- cleanUnnecessary.sh shows an example of which files could be removed after a simulation to save data. This script should be edited to your desired situation perform execution.

= OpenFOAM cases =
Each OpenFOAM example case has the same structure:
- prepareCase.sh prepares the case before execution, e.g., by substituting some variables into template files.
- run.sh is the script which starts the simulation. This script is automatically called by the runAll.sh script in the fluids root folder.
- the cleaning scripts clean up this specific OpenFOAM directory.

The cylindrical cases also have:
- input, yields the variables to setup the geometry and other CFD parameters
- genParticles.sh.tmplt is a template script. The actual script, genParticles.sh, is produced and executed by prepareCase.sh. This script procudes the initial particle positions, randomly distributed over the cylindrical geometry using Aarts et. al.'s volume distribution.

The Carotid Artery cases also have:
- postProcessCase.sh and removeErrParticle. These scripts remove particles that glitched outside of the geometry. Basically, it is a bug in OpenFOAM 2.4.0, that we workaround using these scripts.

= runFoam.sh =
This script does the heavy lifting. A fluids simulation is executed in three steps:

1) A short simulation to let the flow evolve from the set initial condition to a steady state condition. This will serve as the initial condition for the actual case from which we generate results.
A directory called "casename"_IC is automatically generated to perform this simulation.

2) The actual simulation with appropriate fluid deltatime timesteps is executed.
A directory called "casename"_run is automatically generated to perform this simulation.

3) To mimic the camera integration time of a physical camera, the optics simulation will need to perform many simulations in rapid succession. We call this process "microstepping", as was explained in our 2019 and 2022 papers. To that end, we must have the particle positions for each of those microsteps. To produce those particlePositions files, we copy the "casename"_run directory to "casename"_us ("us" stands for "micro-seconds"). Then, for each timestep in step 2, many microsteps are performed. While these are many simulations, these simulations are fast: the ridiculously short timestep makes the CFD simulation converge almost instantly.

The time variables for steps 1 to 3 are set in the "input_time" variables file in the optoFluids case's root directory.

4) If required, the final fourth step is to do some postprocessing.

After these steps, the CFD simulation is finished. The runAll.sh script from the optoFluid case's root directory will now proceed with coupling and optics.



== Coupling / Linking ==
The runAll.sh script in the optoFluid case's root directory will execute the coupling script to convert the output of the fluids code to the input of the optics code.

This example does not include an automatic code to extract particles from the OpenFOAM carorid artery case from sites (see our above 2022 paper), but rather automatically takes ALL particles. However, in the directory called "undocumented" there are some Python scripts that were used to extract particles from sites manually. So you could use those scripts to figure out how to do it yourself as well.



== Optics ==
- runAll.sh executes all required scripts to perform the full optics simulation. runAll.sh is called by ../runAll.sh automatically.
- If this is a HPC simulation, then runAll.sh will submit jobfile.pbs. In thise case, jobfile.pbs takes over the role that runAll.sh would have in a local simulation.

- inputOptics.tmplt is a template file. It contains some variables, between two dollar signs (e.g., $variable$), that are substituted by the substituteMathPy.sh script, which is called by runAll.sh.
- interpolConfig.dat is a file used by the optics code when it is set to precompute the scattering matrix, and interpolate between the precomputing values. This process greatly speeds up the code.
-- You can set the "scattering strategy" at the bottom of the inputOptics.tmplt file. Choose between: "interpolate" (recommended) or "FullBHMie".

- the cleaning scripts clean up the optics folder. cleanResults.sh removes all generated optics files. cleanAll.sh does the same, but it removes the INPUT as produced by the fluids-optics coupling script as well.

- computeSC.sh can compute the speckle contrast for each generated intensity file.
- plotAll.sh can plot all intensity files into a colored contour plot figure. This is _not_ called by runAll.sh by default.

- postProcessAll.sh converts the output of the optics script (intensity files) to a more readable 2D format. Secondly, it sorts those files. Finally, it performs the camera integration process to produce averaged/blurred intensity files to mimic the camera integration time of a physical camera.

This example does NOT compute the speckle contrast, or plot figures, etc.
For an example of how to do that, please check out the other examples, such as "paper2019_exactFlowAndOptics" or "paper2022_atherosclerosisPostProcessing".

