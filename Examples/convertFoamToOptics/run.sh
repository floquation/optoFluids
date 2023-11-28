#! /usr/bin/sh
#
# USAGE:
# ./run.sh -help 
#
# MUST BE EXECUTED FROM THE SCRIPT DIRECTORY
#
# Kevin van As
#  December 2nd 2015

usageString="\n"
usageString+="The run.sh script MUST be executed from the containing directory.\n" 
usageString+="USAGE: ./run.sh [-i path to OpenFOAM case directory] [-o name of output directory]\n"
usageString+="EXAMPLE: ./run.sh -i ../../../OpenFOAM-2.4.x/run/cylinder/cylinderA_usStep\n"
usageString+="EXAMPLE: ./run.sh -i /net/users/$USER/OptoFluids/Simulations/OpenFOAM-2.4.x/run/cylinder/cylinderA_usStep -o my_output_dir\n"
usageString+="Invalid syntax example: ./run.sh -i thisDir thatDir # You cannot have two arguments for one option\n"

FOAM_DIR="../../../OpenFOAM-2.4.x/run/cylinder/cylinderA_usStep"
OUTPUT_DIR="./Foam2OpticsParticles_out"

CheckNr=-1
OFNr=0
OutputNr=1

for f in $@
do
    if [[ $f = "-h" || $f = "-help" ]]; then
        echo -e $usageString
        exit 0
    elif [ $f = "-o" ]; then
        CheckNr=$OutputNr
    elif [ $f = "-i" ]; then
        CheckNr=$OFNr
    elif [ $CheckNr = "-1" ]; then
        echo ""
        echo "Invalid syntax. No option specified, or two arguments specified for the same option."
        echo -e $usageString
        exit 0
    elif [ $CheckNr = $OFNr ]; then
        FOAM_DIR="$f"
        CheckNr=-1
    elif [ $CheckNr = $OutputNr ]; then
        OUTPUT_DIR="$f"
        CheckNr=-1
    fi
done
if [ $CheckNr != "-1" ]; then
    echo ""
    echo "Invalid syntax. Option specified without an argument."
    echo -e $usageString
    exit 0
fi

echo "Using the following OpenFOAM case: $FOAM_DIR"

# This converts the particle cloud called "particles" from the OpenFOAM case directory "$FOAM_DIR" to the input format of the Optics code.
# Note that "-f" is an option that enforces overwrite.
# Some options are optional. Use "$ convertFoam2OpticsParticles.py -help" to find out more information.
convertFoam2OpticsParticles.py -i $FOAM_DIR -c particles -o $OUTPUT_DIR -f





