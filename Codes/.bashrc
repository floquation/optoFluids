# Source this file to add all bin directories to the required environmental variables
#
# - Kevin van As
#	27 11 2015: Original
#	10 09 2018: Added PYTHONPATH
#	18 03 2019: Restructured particle-generation and optics-sorting scripts.
#
# TODO:
# - Distinguish between MSFF and SSFF code
# - Make a template for proof-of-principle case
#
#

#THIS_PWD="$PWD/$(dirname ${BASH_SOURCE[@]})"
#echo "THIS_PWD = $THIS_PWD"
#echo "${BASH_SOURCE[@]}"
#echo "${BASH_SOURCE[0]}"
THIS_PWD=`cd $(dirname  ${BASH_SOURCE[0]}) > /dev/null && echo $PWD`
#echo "THIS_PWD = $THIS_PWD"
#echo $PWD


# PATH: for from-terminal execution of scripts
pathprepend "$THIS_PWD/PreProcessing"
pathprepend "$THIS_PWD/PreProcessing/generateParticles"
pathprepend "$THIS_PWD/PreProcessing/OptoFluids"
pathprepend "$THIS_PWD/PostProcessing"
pathprepend "$THIS_PWD/PostProcessing/Plotting"
pathprepend "$THIS_PWD/Coupling"
pathprepend "$THIS_PWD/Optics/Mie_MSFF"
pathprepend "$THIS_PWD/Optics/processOutput"
pathprepend "$THIS_PWD/Fluids"
pathprepend "$THIS_PWD/Fluids/exact"
pathprepend "$THIS_PWD/templating"

# Export useful bash functions
source "$THIS_PWD/bash_functions/bashmath" # Math in terminal

# PYTHONPATH: for finding Python modules inside Python scripts
pathprepend "$THIS_PWD" PYTHONPATH
