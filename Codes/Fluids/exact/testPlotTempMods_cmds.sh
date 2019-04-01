# N.B.: Edit testPlotTempMod.py manually to set appropriate min/max lines!plug

# Sinusoidal:
python3 testPlotTempMod.py --mod="sin" --modargs="amplitude=0.375;frequency=1" --t1=$(mathPy "1.0*2") -o sinusoidal --dt 0.005
# Heartbeat Baker 2017:
python3 testPlotTempMod.py --mod="lookupTable" --modargs="heartbeat/heartbeatVelo_Baker2017" --t1=$(mathPy "0.835*2") -o heartbeat_Baker2017 --dt 0.005

