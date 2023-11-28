pyFoamClearCase.py base
rm base/PyFoamHistory
rm -rf base_ICgen
rm -rf base_run
rm -rf base_us

cd base_parallel >/dev/null && ./cleanCase.sh && cd - > /dev/null
rm -rf base_parallel_ICgen
rm -rf base_parallel_run
rm -rf base_parallel_us

cd CarotidArtery_parallel >/dev/null && ./cleanCase.sh && cd - > /dev/null
rm -rf CarotidArtery_parallel_ICgen
rm -rf CarotidArtery_parallel_run
rm -rf CarotidArtery_parallel_us

rm -f jobfile.pbs
