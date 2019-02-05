num=0
[ "$1" != "" ] && num="$1" && shift
heartbeat="heartbeatVelo_original"
./moveParticles.py -R 1e-3 -L 1e-2 -i "testFiles/pos_t$num" --flow=Poiseuille -u 0.05 -o output --mod lookupTable --modargs "heartbeat/$heartbeat","boundaryStrategy=cyclic" $@
