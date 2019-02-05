# Begin ~/.bashrc
# by Kevin van As <info@kevinvanas.nl>
# inspired by <http://www.linuxfromscratch.org/~krejzi/kde5/postlfs/profile.html>

# Personal aliases and functions.

# Personal environment variables and startup programs should go in
# ~/.bash_profile.  System wide environment variables and startup
# programs are in /etc/profile.  System wide aliases and functions are
# in /etc/bashrc.

#/****************************\
#|           ALIASES          |
#\****************************/


# rm (cf. https://github.com/andreafrancia/trash-cli/)
alias rm='echo "rm is disabled, use \"myrm\" or \"/bin/rm\" instead."'
alias myrm="mv -i -t $HOME/.local/share/Trash/ ${*}"
alias emptybin="echo \"Sleeping for 5 seconds before removing Trash permanently.\"; echo \"Use Cntrl+C to abort and 'showTrash' to view what's in your Trashcan!\"; sleep 5 && (echo \"Now starting to clear Trash.\"; 'rm' -rf $HOME/.local/share/Trash/*; echo \"Trash cleared.\")"
alias showTrash="ll -Ah $HOME/.local/share/Trash/"
alias gotoTrash="cd $HOME/.local/share/Trash/"

alias whereami="pwd; ls;"
alias whatami="echo 'I suppose you are a human. If not, you must be another intelligent being, who thinks about his own existence.'"
alias imlost="clear; whereami"

# http://stackoverflow.com/questions/2507766/merge-convert-multiple-pdf-files-into-one-pdf
alias pdfmerge="gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile=mymergedpdfdocument.pdf"

#alias splitcolon='echo -e ${1//:/\\n}' # DOES NOT WORK
#alias splitcolon='echo $1 | sed -e ''s/:/\\n/g''' # DOES NOT WORK
alias path='echo -e ${PATH//:/\\n}'
alias ld_library_path='echo -e ${LD_LIBRARY_PATH//:/\\n}'

alias gotoTPServer="cd /net/users/$USER/"


