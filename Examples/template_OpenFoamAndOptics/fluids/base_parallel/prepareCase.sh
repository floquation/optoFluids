#! /bin/sh
# MUST BE CALLED FROM THE CASE ROOT FOLDER

#####
# DO NOT TOUCH BELOW
###
TEMPLATE_VARS_FILE=input
#TEMPLATE=someTemplate


# transportProperties
THE_FILE="constant/transportProperties"
templateSubstitutor.py -t "$THE_FILE.tmplt" -v "$TEMPLATE_VARS_FILE" -o "$THE_FILE" -f || exit

# particleProperties
THE_FILE="constant/particlesProperties"
templateSubstitutor.py -t "$THE_FILE.tmplt" -v "$TEMPLATE_VARS_FILE" -o "$THE_FILE" -f || exit

# system/"swak4FoamDicts"
THE_FILE="system/particleCloudDict"
templateSubstitutor.py -t "$THE_FILE.tmplt" -v "$TEMPLATE_VARS_FILE" -o "$THE_FILE" -f || exit

# 0-directory
rm -rf "0"
cp -r "0.tmplt" "0"
templateSubstitutor.py -t "0/p.tmplt" -v "$TEMPLATE_VARS_FILE" -o "0/p" -f || exit
templateSubstitutor.py -t "0/U.tmplt" -v "$TEMPLATE_VARS_FILE" -o "0/U" -f || exit
rm 0/*.tmplt

## system/decomposeParDict
#THE_FILE="system/decomposeParDict"
#templateSubstitutor.py -t "$THE_FILE.tmplt" -v "$TEMPLATE_VARS_FILE" -o "$THE_FILE" -f || exit

## ./run.sh
#THE_FILE="./run.sh"
#templateSubstitutor.py -t "$THE_FILE.tmplt" -v "$TEMPLATE_VARS_FILE" -o "$THE_FILE" -f || exit
#chmod a+wx "$THE_FILE"

# Generate blockMeshDict
BLOCK_MESH_DICT="constant/polyMesh/blockMeshDict"
templateSubstitutor.py -t "$BLOCK_MESH_DICT.tmplt" -v "$TEMPLATE_VARS_FILE" -o "$BLOCK_MESH_DICT" -f || exit

# Make mesh
blockMesh || exit 1

# Generate particles
GEN_PART_SCRIPT="genParticles.sh"
templateSubstitutor.py -t "$GEN_PART_SCRIPT.tmplt" -v "$TEMPLATE_VARS_FILE" -o "$GEN_PART_SCRIPT" -f || exit
sh $GEN_PART_SCRIPT
#rm "$GEN_PART_SCRIPT"

# Decompose parallel
decomposePar
