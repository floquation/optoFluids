# Begin ~/.bash_profile
# by Kevin van As <info@kevinvanas.nl>
# inspired by <http://www.linuxfromscratch.org/~krejzi/kde5/postlfs/profile.html>

# Personal environment variables and startup programs.

# Personal aliases and functions should go in ~/.bashrc.  System wide
# environment variables and startup programs are in /etc/profile.
# System wide aliases and functions are in /etc/bashrc.

#echo "Hello from ~/.bash_profile!"

if [ -f "$HOME/.bashrc" ]; then # .bashrc is not loaded on all terminals. It is not loaded with an interactive login shell (e.g. when using PuTTY).
	source $HOME/.bashrc
fi

#/****************************\
#|          FUNCTIONS         |
#\****************************/

# Taken from: http://www.linuxfromscratch.org/~krejzi/kde5/postlfs/profile.html
pathremove () {
        local IFS=':' # Makes the for-loop split on ':' instead of the default (' ').
        local NEWPATH
        local DIR
        local PATHVARIABLE=${2:-PATH} # Holds "PATH" (default) or $2 otherwisely. I.e., the name of the environmental variable we are affecting.
        for DIR in ${!PATHVARIABLE} ; do # Walk through the current $PATHVARIABLE to see if $1 already exists
                if [ "$DIR" != "$1" ] ; then # If so, ignore it when reconstructing $NEWPATH:
                  NEWPATH=${NEWPATH:+$NEWPATH:}$DIR #Appends ":$DIR" to $NEWPATH if $NEWPATH exists. Otherwise writes $DIR to $NEWPATH.
                fi
        done
        export $PATHVARIABLE="$NEWPATH" # We have succesfully removed $1 from $PATHVARIABLE
}

# Taken from: http://www.linuxfromscratch.org/~krejzi/kde5/postlfs/profile.html
# Prepends $1 to $2 (default: $2=PATH).
# Removes $1 first, if it already existed and then re-adds it.
pathprepend () {
        pathremove $1 $2
        local PATHVARIABLE=${2:-PATH}
        export $PATHVARIABLE="$1${!PATHVARIABLE:+:${!PATHVARIABLE}}"
}

# Taken from: http://www.linuxfromscratch.org/~krejzi/kde5/postlfs/profile.html
# Appends $1 to $2 (default: $2=PATH).
# Removes $1 first, if it already existed and then re-adds it.
pathappend () {
        pathremove $1 $2
        local PATHVARIABLE=${2:-PATH}
        export $PATHVARIABLE="${!PATHVARIABLE:+${!PATHVARIABLE}:}$1"
}

export -f pathremove pathprepend pathappend 


# Execute scripts in series
# Usage: execseries "command 1" "command 2" "command 3"
# Note: Be careful with quotes inside commands, as they will cancel the quotes above.
#       So make sure to escape them appropriately.
#       Warning: execseries "echo \"hello world\"" will print hello; the text "world" is seen as a new function, which is not desired.
#                execseries "echo \\\"hello world\\\"" will print "hello world" (including quotes) <---------------------------------- This is probably what you want
#                execseries "echo hello world" will print hello world
#                execseries "echo "hello world"" is identical to "echo \"hello world\""
#       It is advised to try to "echo" first, before actually executing your own script.
# Kevin van As, April 08 2016
execseries () {
    #echo '$@='"$@"
    if [ "$#" -eq 0 ] ; then
        echo "Specified zero arguments! Exiting."
        return 0
    fi

    # Build execution command
    # 1) Build arguments
    counter=-1
    exe='$0'
    for arg in "$@" ; do
        counter=$((counter+1))
        if [ $counter -eq 0 ] ; then
            continue
        fi
        exe="$exe && \$$counter"
        #echo $exe
    done

    # 2) Add nohup etc. in front
    exe='nohup nice -n 19 sh -c '"'$exe'"

    # 3) Add the executables in the end
    for arg in "$@" ; do
        #echo $arg
        exe="$exe \"$arg\""
    done
    exe="$exe &"

    # And then execute it
    echo "Execution string = " $exe
    sh -c "$exe"
    #$("$exe")
    #echo $! 
}

export -f execseries 

# Generate a comment of the form:
# /************\
# |            |
# | my message |
# |            |
# \************/
#
# Usage:
#   makeComment "message" ["prefix"]
#   makeComment "my message" "# "
#
# The prefix is useful in case you wish to prepend e.g. a "#", which is the comment character in bash.
#
# Kevin van As, April 28 2016
makeComment() {
    msg="$1"
    prefix="$2"

    length="${#msg}"

    stars=""
    spaces=""
    for ((i=0;i<$((length+2));i++)); do
        stars=$stars"*"
        spaces=$spaces" "
    done
    echo "$prefix""/$stars\\"
    echo "$prefix|$spaces|"
    echo "$prefix| $msg |"
    echo "$prefix|$spaces|"
    echo "$prefix""\\$stars/"
}

export -f makeComment

#/****************************\
#|   ENVIRONMENTAL VARIABLES  |
#\****************************/

export INPUTRC=~/.inputrc

# General
pathprepend ~/.local/bin

## Separate programs

# anaconda (Python)
#pathprepend $OPTOFLUIDS_DIR/anaconda2/bin
#pathprepend $OPTOFLUIDS_DIR/anaconda2/lib LD_LIBRARY_PATH

# eclipse
#pathprepend $OPTOFLUIDS_DIR/eclipse

# TeX
#pathprepend $OPTOFLUIDS_DIR/TeXLive/build/texmf-dist/doc/info INFOPATH
#pathprepend $OPTOFLUIDS_DIR/TeXLive/build/texmf-dist/doc/man MANPATH
#pathprepend $OPTOFLUIDS_DIR/TeXLive/build/bin/x86_64-linux PATH

# gcc
#pathprepend $OPTOFLUIDS_DIR/gcc/build/bin
#pathprepend $OPTOFLUIDS_DIR/gcc/builddeps/lib LD_LIBRARY_PATH # Required by gcc to execute gcc
#pathprepend $OPTOFLUIDS_DIR/gcc/build/lib LD_LIBRARY_PATH # Required by gcc to execute gcc
#pathprepend $OPTOFLUIDS_DIR/gcc/build/lib64 LD_LIBRARY_PATH # Required by gcc to execute gcc
pathprepend /home/kevinvanas/Applications/gcc/build/bin
pathprepend /home/kevinvanas/Applications/gcc/builddeps/lib LD_LIBRARY_PATH # Required by gcc to execute gcc
pathprepend /home/kevinvanas/Applications/gcc/build/lib LD_LIBRARY_PATH # Required by gcc to execute gcc
pathprepend /home/kevinvanas/Applications/gcc/build/lib64 LD_LIBRARY_PATH # Required by gcc to execute gcc

# # #

# Other variables
pathappend . CDPATH
#pathappend ~ CDPATH

pathappend "&" 		HISTIGNORE
pathappend "ls" 	HISTIGNORE
#pathappend "ls *" 	HISTIGNORE
pathappend "ll" 	HISTIGNORE
pathappend "whereami" 	HISTIGNORE
pathappend "whatami" 	HISTIGNORE
pathappend "imlost" 	HISTIGNORE
#pathappend "ll *" 	HISTIGNORE
pathappend "[bf]g" 	HISTIGNORE
pathappend "exit" 	HISTIGNORE
pathappend "emptybin" 	HISTIGNORE
pathappend "showTrash" 	HISTIGNORE

set -o ignoreeof # Disables Cntrl+D to logout from the shell; See: http://www.caliban.org/bash/index.shtml

shopt -s extglob # Enables egrep-style pattern matching; See: http://www.caliban.org/bash/index.shtml



#/****************************\
#|     START-UP PROGRAMS      |
#\****************************/






# End ~/.bash_profile
