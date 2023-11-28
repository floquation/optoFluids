pyFoamClearCase.py base
rm base/PyFoamHistory
rm -rf base_ICgen # its result is the IC of base_run, so we already have it!
#rm -rf base_run # expensive to generate, so let's keep it as a return point!
rm -rf base_us # cheap to generate, so remove
