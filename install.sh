# Get script dir
scriptDir=${0%/*}
if [ "$scriptDir" == "bash" ]; then
    echo " ERROR: You cannot source this script!"
    return
fi
cd $scriptDir > /dev/null
scriptDir=$(pwd)
cd - > /dev/null

# Detect existence of .bash_profile, .bashrc, etc.:
if [ ! -f "$HOME/.vimrc" ]; then
    cp "$scriptDir/.vimrc" "$HOME/.vimrc"
fi
if [ -f "$HOME/.bash_profile" ]; then
    # .bash_profile does already exist
    echo ""
    echo " #@!%"
    echo " | WARNING: ~/.bash_profile ALREADY EXISTS. PLEASE CHECK IT MANUALLY."
    echo " #@!%"
    echo ""
else
    # .bash_profile does not exist: copy our .bash_profile
    cp "$scriptDir/.bash_profile" "$HOME/.bash_profile"
fi
if [ -f "$HOME/.bashrc" ]; then
    # .bashrc does already exist
    # Check if it is empty
    if [ "$(cat "$HOME/.bashrc" | wc -l )" = "0" ]; then
        # Empty, so overwrite
        echo "empty ~/.bashrc: overwriting" 
        cp "$scriptDir/.bashrc" "$HOME/.bashrc"
    else
        # Not empty
        echo ""
        echo " #@!%"
        echo " | WARNING: ~/.bashrc ALREADY EXISTS. PLEASE CHECK IT MANUALLY."
        echo " #@!%"
        echo ""
    fi
else
    # .bashrc does not exist: copy our .bash_profile
    cp "$scriptDir/.bashrc" "$HOME/.bashrc"
fi

# install optofluidsrc
echo "" >> ~/.bashrc
echo '# OptoFluids:' >> ~/.bashrc
echo 'alias loadoptofluids="source '"$scriptDir"'/.optofluidsrc"' >> ~/.bashrc
echo "" >> ~/.bashrc
echo '# OpenFOAM:' >> ~/.bashrc
if [ -d "/opt/apps/openfoam-2.4.0" ]; then
	# local machine
	echo 'alias of240="export FOAM_INST_DIR=/opt/apps/openfoam-2.4.0 && echo Using OpenFOAM installation: "'"'"'$FOAM_INST_DIR'"'"'" && source "'"'"'$FOAM_INST_DIR'"'"'"/OpenFOAM-2.4.0/etc/bashrc WM_MPLIB=OPENMPI WM_PROJECT_USER_DIR=/net/users/'"$USER"'/OpenFOAM/OpenFOAM-2.4.x && pathprepend '$scriptDir'/Applications/PyFoam/bin && pathprepend '$scriptDir'/Applications/swak4Foam-2.4.x/privateRequirements/bin && echo '"'"'OpenFOAM 2.4.0 loaded successfully'"'"'"' >> ~/.bashrc
else
	# cluster
	echo 'alias of240="module load openfoam/2.4.0 && pathprepend /home/kevinvanas/Applications/PyFoam_bin/bin && pathprepend /home/kevinvanas/Applications/PyFoam_bin/lib/python2.7/site-packages/ PYTHONPATH && pathprepend /home/kevinvanas/Applications/swak4Foam/swak4Foam-2.4.x/privateRequirements/bin && echo '"'"'OpenFOAM 2.4.0 loaded successfully'"'"'"' >> ~/.bashrc
	echo 'alias of41="module load openfoam/4.1 && pathprepend /home/kevinvanas/Applications/PyFoam_bin/bin && pathprepend /home/kevinvanas/Applications/PyFoam_bin/lib/python2.7/site-packages/ PYTHONPATH && pathprepend /home/kevinvanas/Applications/swak4Foam/swak4Foam-4.0/privateRequirements/bin && echo '"'"'OpenFOAM 4.1 loaded successfully'"'"'"' >> ~/.bashrc
fi

# TODO: Make of240 alias known in this script
#source ~/.bashrc
#of240 > /dev/null
#mkdir -p "$FOAM_USER_LIBBIN"
#mkdir -p "$FOAM_USER_APPBIN"
#cp $(echo "$FOAM_USER_LIBBIN" | sed 's/'"$USER"'/kevinvanas/g')/* "$FOAM_USER_LIBBIN"
#cp $(echo "$FOAM_USER_APPBIN" | sed 's/'"$USER"'/kevinvanas/g')/* "$FOAM_USER_APPBIN"


#echo 'alias of240="export FOAM_INST_DIR=/opt/apps/openfoam-2.4.0 && echo Using OpenFOAM installation: "'"'"'$FOAM_INST_DIR'"'"'" && source "'"'"'$FOAM_INST_DIR'"'"'"/OpenFOAM-2.4.0/etc/bashrc WM_MPLIB=OPENMPI WM_PROJECT_USER_DIR='$scriptDir'/Simulations/OpenFOAM-2.4.x && pathprepend '$scriptDir'/Applications/PyFoam/lib64/python2.6/site-packages/ PYTHONPATH && pathprepend '$scriptDir'/Applications/PyFoam/bin && pathprepend '$scriptDir'/Applications/swak4Foam-2.4.x/privateRequirements/bin && echo '"'"'OpenFOAM 2.4.0 loaded successfully'"'"'"' >> ~/.bashrc

# Messages
echo " Thank you for using our software. Although you probably didn't have any choice at all."
echo " For your information, your \"~/.bashrc\" file has been changed."
echo " You might want to have a look at what happened:"
echo " $ gedit ~/.bashrc"
echo " NOTE: Do not edit that file!"
echo ""
echo " After finalising the installing, you can load the OptoFluids code by typing:"
echo " $ loadoptofluids"
echo " and OpenFoam-2.4.x by typing:"
echo " $ of240"
echo ""
echo "----"
echo "| Installation completed. Please check any WARNING/ERROR messages above."
echo "| If no error occured, please relog to your system to finalise the installation."
echo "--------"

