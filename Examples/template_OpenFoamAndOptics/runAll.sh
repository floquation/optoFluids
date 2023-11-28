# This script runs the fluids_openfoam + optics simulations.

fluidsDN="fluids"
fluids_case="base" # CHANGE THIS to the fluid example case you chose in the fluids folder in its runAll.sh script.

# Fluids
echo "--- runAll.sh: running fluids: \"$fluidsDN\" ---"
cd "$fluidsDN" > /dev/null
./runAll.sh || exit 1
cd - > /dev/null

# Coupling
echo "--- runAll.sh: running coupling ---"
convertFoam2OpticsParticles.sh "$fluidsDN/$fluids_case"_us "optics/particlePositions" particles

# Optics
echo "--- runAll.sh: running optics ---"
cd optics > /dev/null
./runAll.sh || exit 1
cd - > /dev/null


# EOF
