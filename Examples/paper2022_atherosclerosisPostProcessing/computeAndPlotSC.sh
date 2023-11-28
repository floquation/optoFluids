baseDN="../simulations/optics/"

## Compute speckle contrast
#./computeSC.sh "$baseDN" "results_backup/SiteA" > "SC_A.csv" || exit 1
#./computeSC.sh "$baseDN" "results_us/SiteB" > "SC_B.csv" || exit 1
#./computeSC.sh "$baseDN" "results_backup/SiteC" > "SC_C.csv" || exit 1
#./computeSC.sh "$baseDN" "results_us/SiteD" > "SC_D.csv" || exit 1
#./computeSC.sh "$baseDN" "results_us/SiteE" > "SC_E.csv" || exit 1

## Plot speckle contrast
./plotSC.sh . "_A" || exit 1
./plotSC.sh . "_B" || exit 1
./plotSC.sh . "_C" || exit 1
./plotSC.sh . "_D" || exit 1
./plotSC.sh . "_E" || exit 1



