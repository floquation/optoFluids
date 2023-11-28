Requirements:
- gcc 4.9.2 (required to compile the Fortran optics code)
- anaconda3 (3.9.7) (so Python + packages)
- texlive (latex, required for some of the axis of the graph-making scripts)
- openfoam 2.4.0 (only if openfoam fluid simulations are used as an input to the optics code) (newer versions should also be possible, but the particle extraction scripts might need adapting if OpenFoam changes the layout of the particlePositions file in a newer version)
-- PyFoam
-- swak4Foam

Put these programs in this folder, or edit the file ".optofluidsrc" to point to their installed location.

TODO: latex install has failed. This only has consequences for graph-making scripts that use latex for the axes.
