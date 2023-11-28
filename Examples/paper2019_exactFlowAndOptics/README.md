This example combines fluid dynamics with optics, as was first seen in our 2019 paper:
Van As, K., Boterman, J., Kleijn, C. R., Kenjeres, S., & Bhattacharya, N. (2019). Laser speckle imaging of flowing blood: A numerical study. Physical Review E, 100(3), 033317.

The fluid dynamics calculation starts with a random distribution of particles, that are evolved using an exact flow profile. There is no Computational Fluid Dynamics (CFD) software used for this template case.

==== Files ====

Before you start doing anything, make sure the modules are loaded by typing
$ loadoptofluids

== Root optoFluids case directory ==
- jobfile.pbs is a script to be executed on a high-performance cluster (HPC). To run it locally, rework it into a runAll.sh script yourself, as can be seen in other examples.
- input_names and input_time are datafiles, that are sourced by scripts in the fluids and optics folders. These variables are shared between fluids and optics.
- cleanAll.sh removes ALL generated files. Don't use that on your data. ;-)

== Fluids ==
- runAll.sh executes all required scripts to perform the full fluid simulation. runAll.sh is called by ../jobfile.pbs automatically.
-- It creates initial particles based on the variables set in the input_flow file, and then evolves them over time based on the variables set.
- input_flow holds all variables that are only relevant to the fluid dynamics simulation

== Optics ==
- runAll.sh executes all required scripts to perform the full optics simulation. runAll.sh is called by ../jobfile.pbs automatically.
-- The result of the optics code is a set of intensity files: one for each microtimestep (i.e., the small delta times used to mimic the camera integration time of a real camera).
-- The script processOpticsOutput.sh, as called by runAll.sh, converts the output of the optics code into a more readable 2D format, it sorts the files, and it performs the camera integration calculation.
- inputOptics.tmplt is a template file. It contains some variables, between two dollar signs (e.g., $variable$), that are substituted by the substituteMathPy.sh script, which is called by runAll.sh.
- interpolConfig.dat is a file used by the optics code when it is set to precompute the scattering matrix, and interpolate between the precomputing values. This process greatly speeds up the code.
-- You can set the "scattering strategy" at the bottom of the inputOptics.tmplt file. Choose between: "interpolate" (recommended) or "FullBHMie".
- computeSC.sh can compute the speckle contrast for each generated intensity file.
- plotAll.sh can plot all intensity files into a colored contour plot figure. This is _not_ called by runAll.sh by default.
- jobfile.pbs is not used, but could be used to redo the optics simulation without redo-ing everything including the fluids simulation.
