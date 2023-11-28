#! /bin/sh
POS_FILE=constant/particlesPositions
tmpPOS_FILE=constant/.particlesPositions.tmp
cat $POS_FILE.header > $POS_FILE
echo "(" >> $POS_FILE
genCylParticles.py -i "$OPTOFLUIDS_DIR/Codes/PreProcessing/AartsFig4_probAccum.dat" -o "$tmpPOS_FILE" -N "100" -R "8E-3" -L "1E-2" -O "(0,0,0)" 
cat $tmpPOS_FILE >> $POS_FILE
rm $tmpPOS_FILE
echo ")" >> $POS_FILE
