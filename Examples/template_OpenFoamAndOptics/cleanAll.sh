# Fluids
echo "--- cleanAll.sh: running fluids ---"
for fluids in ./fluid*
do
	cd "$fluids" > /dev/null
	./cleanAll.sh || exit 1
	cd - > /dev/null
done

# Optics
echo "--- cleanAll.sh: running optics ---"
cd optics > /dev/null
./cleanAll.sh || exit 1
cd - > /dev/null


# EOF
