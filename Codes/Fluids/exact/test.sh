num=0
[ "$1" != "" ] && num="$1" && shift
heartbeat="heartbeatVelo_original"

# Evolve:
#./moveParticles.py -R 1e-3 -L 1e-2 -i "testFiles/pos_t$num" --flow=Poiseuille -u 0.05 -o output --mod lookupTable --modargs "heartbeat/$heartbeat","boundaryStrategy=cyclic" $@
#./moveParticles.py -R 1e-3 -L 1e-2 -i "testFiles/pos_t$num" --flow=Poiseuille -u 0.05 -o output --mod sin --modargs "frequency=2","amplitude=0.2" $@

# Plot:
#python3 testPlotTempMod.py --mod="sin" --modargs="frequency=2","amplitude=0.2" --dt=0.01
#python3 testPlotTempMod.py --mod lookupTable --modargs "heartbeat/heartbeatVelo_original","boundaryStrategy=cyclic" --t1 3 --dt 0.01
